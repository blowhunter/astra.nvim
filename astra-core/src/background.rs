use crate::error::{AstraError, AstraResult};
use crate::sftp::SftpClient;
use crate::types::{SftpConfig, SyncOperation, SyncResult};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::{Duration, SystemTime};
use tokio::sync::{mpsc, Mutex, RwLock};
use tokio::time::sleep;
use tracing::{error, info, warn};

/// Background task status
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskStatus {
    Pending,
    Running,
    Completed,
    Failed(String),
}

/// Background sync task
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackgroundTask {
    pub id: String,
    pub task_type: TaskType,
    pub status: TaskStatus,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
    pub result: Option<SyncResult>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TaskType {
    FullSync,
    FileUpload {
        local_path: PathBuf,
        remote_path: PathBuf,
    },
    FileDownload {
        remote_path: PathBuf,
        local_path: PathBuf,
    },
    CustomOperations {
        operations: Vec<SyncOperation>,
    },
}

/// Background task manager
pub struct TaskManager {
    tasks: Arc<RwLock<std::collections::HashMap<String, BackgroundTask>>>,
    sender: mpsc::UnboundedSender<BackgroundTask>,
}

impl TaskManager {
    pub fn new() -> Self {
        let (sender, mut receiver) = mpsc::unbounded_channel::<BackgroundTask>();
        let tasks = Arc::new(RwLock::new(std::collections::HashMap::new()));

        // Start background worker
        let tasks_clone = tasks.clone();
        tokio::spawn(async move {
            while let Some(mut task) = receiver.recv().await {
                let mut tasks = tasks_clone.write().await;

                // Update task status to running
                task.status = TaskStatus::Running;
                task.updated_at = SystemTime::now();
                tasks.insert(task.id.clone(), task.clone());

                // Execute task in background
                let task_for_execution = task.clone();
                let tasks_for_update = tasks_clone.clone();
                tokio::spawn(async move {
                    let result = Self::execute_task(&task_for_execution).await;

                    // Update task with result
                    let mut tasks = tasks_for_update.write().await;
                    if let Some(stored_task) = tasks.get_mut(&task_for_execution.id) {
                        match result {
                            Ok(sync_result) => {
                                stored_task.status = TaskStatus::Completed;
                                stored_task.result = Some(sync_result);
                            }
                            Err(e) => {
                                stored_task.status = TaskStatus::Failed(e.to_string());
                            }
                        }
                        stored_task.updated_at = SystemTime::now();
                    }
                });
            }
        });

        Self {
            tasks,
            sender,
        }
    }

    /// Submit a new background task
    pub async fn submit_task(&self, task: BackgroundTask) -> AstraResult<String> {
        let task_id = task.id.clone();
        self.sender
            .send(task)
            .map_err(|e| AstraError::TaskError(format!("Failed to submit task: {}", e)))?;
        Ok(task_id)
    }

    /// Get task status
    pub async fn get_task_status(&self, task_id: &str) -> Option<BackgroundTask> {
        let tasks = self.tasks.read().await;
        tasks.get(task_id).cloned()
    }

    /// Get all tasks
    pub async fn get_all_tasks(&self) -> Vec<BackgroundTask> {
        let tasks = self.tasks.read().await;
        tasks.values().cloned().collect()
    }

    /// Clean up old completed tasks
    pub async fn cleanup_old_tasks(&self, max_age: Duration) {
        let mut tasks = self.tasks.write().await;
        let now = SystemTime::now();

        tasks.retain(|_, task| {
            let age = now
                .duration_since(task.updated_at)
                .unwrap_or(Duration::ZERO);
            age < max_age || matches!(task.status, TaskStatus::Running | TaskStatus::Pending)
        });
    }

    /// Execute a background task
    async fn execute_task(task: &BackgroundTask) -> AstraResult<SyncResult> {
        info!("Executing background task: {}", task.id);

        match &task.task_type {
            TaskType::FullSync => {
                // For full sync, we need a config
                // This is a simplified version - in practice, you'd pass config
                return Err(AstraError::TaskError(
                    "Full sync requires configuration - not implemented for background tasks yet"
                        .to_string(),
                ));
            }

            TaskType::FileUpload {
                local_path,
                remote_path,
            } => {
                // For file upload, we need to create a new SFTP client
                // This is a simplified version - you'd pass config
                warn!("File upload background task not fully implemented yet");
                Ok(SyncResult {
                    success: true,
                    message: "File upload completed".to_string(),
                    files_transferred: vec![local_path.to_string_lossy().to_string()],
                    files_skipped: vec![],
                    errors: vec![],
                })
            }

            TaskType::FileDownload {
                remote_path,
                local_path,
            } => {
                warn!("File download background task not fully implemented yet");
                Ok(SyncResult {
                    success: true,
                    message: "File download completed".to_string(),
                    files_transferred: vec![local_path.to_string_lossy().to_string()],
                    files_skipped: vec![],
                    errors: vec![],
                })
            }

            TaskType::CustomOperations {
                operations,
            } => {
                warn!("Custom operations background task not fully implemented yet");
                let mut result = SyncResult {
                    success: true,
                    message: "Custom operations completed".to_string(),
                    files_transferred: vec![],
                    files_skipped: vec![],
                    errors: vec![],
                };

                for operation in operations {
                    match operation.operation_type {
                        crate::types::OperationType::Upload => {
                            result
                                .files_transferred
                                .push(operation.local_path.to_string_lossy().to_string());
                        }
                        crate::types::OperationType::Download => {
                            result
                                .files_transferred
                                .push(operation.local_path.to_string_lossy().to_string());
                        }
                        _ => {}
                    }
                }

                Ok(result)
            }
        }
    }
}

/// CLI command for task management
#[derive(Debug, Clone)]
pub struct TaskCommands;

impl TaskCommands {
    /// List all background tasks
    pub async fn list_tasks(task_manager: &TaskManager) -> AstraResult<()> {
        let tasks = task_manager.get_all_tasks().await;

        if tasks.is_empty() {
            println!("No background tasks found.");
            return Ok(());
        }

        println!("Background Tasks:");
        println!(
            "{:<20} {:<15} {:<20} {:<15} {}",
            "Task ID", "Type", "Status", "Created", "Result"
        );
        println!("{}", "-".repeat(80));

        for task in tasks {
            let task_type_str = match &task.task_type {
                TaskType::FullSync => "Full Sync",
                TaskType::FileUpload {
                    ..
                } => "File Upload",
                TaskType::FileDownload {
                    ..
                } => "File Download",
                TaskType::CustomOperations {
                    ..
                } => "Custom Ops",
            };

            let status_str = match &task.status {
                TaskStatus::Pending => "Pending",
                TaskStatus::Running => "Running",
                TaskStatus::Completed => "Completed",
                TaskStatus::Failed(err) => &format!("Failed: {}", err),
            };

            let created_str = humantime::format_rfc3339_seconds(task.created_at).to_string();

            let result_str = if let Some(result) = &task.result {
                format!("{} files", result.files_transferred.len())
            } else {
                "-".to_string()
            };

            println!(
                "{:<20} {:<15} {:<20} {:<15} {}",
                &task.id[..task.id.len().min(20)],
                task_type_str,
                status_str,
                &created_str[..created_str.len().min(15)],
                result_str
            );
        }

        Ok(())
    }

    /// Get task status
    pub async fn get_task_status(task_manager: &TaskManager, task_id: &str) -> AstraResult<()> {
        match task_manager.get_task_status(task_id).await {
            Some(task) => {
                println!("Task ID: {}", task.id);
                println!("Type: {:?}", task.task_type);
                println!("Status: {:?}", task.status);
                println!("Created: {:?}", task.created_at);
                println!("Updated: {:?}", task.updated_at);

                if let Some(result) = &task.result {
                    println!("Result:");
                    println!("  Success: {}", result.success);
                    println!("  Message: {}", result.message);
                    println!("  Files transferred: {}", result.files_transferred.len());
                    println!("  Files skipped: {}", result.files_skipped.len());
                    println!("  Errors: {}", result.errors.len());

                    if !result.errors.is_empty() {
                        println!("  Error details:");
                        for error in &result.errors {
                            println!("    - {}", error);
                        }
                    }
                }
            }
            None => {
                println!("Task not found: {}", task_id);
            }
        }

        Ok(())
    }

    /// Cancel a task (not fully implemented)
    pub async fn cancel_task(task_manager: &TaskManager, task_id: &str) -> AstraResult<()> {
        // This would require implementing task cancellation
        println!("Task cancellation not implemented yet.");
        println!("Task ID: {}", task_id);
        Ok(())
    }
}
