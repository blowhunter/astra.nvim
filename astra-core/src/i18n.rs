use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use std::env;

/// Supported languages
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Language {
    #[serde(rename = "en")]
    English,
    #[serde(rename = "zh")]
    Chinese,
    #[serde(rename = "ja")]
    Japanese,
    #[serde(rename = "ko")]
    Korean,
    #[serde(rename = "es")]
    Spanish,
    #[serde(rename = "fr")]
    French,
    #[serde(rename = "de")]
    German,
    #[serde(rename = "ru")]
    Russian,
}

impl Default for Language {
    fn default() -> Self {
        Language::English
    }
}

impl Language {
    /// Try to parse language from string
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "en" | "english" => Some(Language::English),
            "zh" | "chinese" | "cn" => Some(Language::Chinese),
            "ja" | "japanese" => Some(Language::Japanese),
            "ko" | "korean" => Some(Language::Korean),
            "es" | "spanish" => Some(Language::Spanish),
            "fr" | "french" => Some(Language::French),
            "de" | "german" => Some(Language::German),
            "ru" | "russian" => Some(Language::Russian),
            _ => None,
        }
    }

    /// Get language name in English
    pub fn name(&self) -> &'static str {
        match self {
            Language::English => "English",
            Language::Chinese => "Chinese",
            Language::Japanese => "Japanese",
            Language::Korean => "Korean",
            Language::Spanish => "Spanish",
            Language::French => "French",
            Language::German => "German",
            Language::Russian => "Russian",
        }
    }

    /// Get native language name
    pub fn native_name(&self) -> &'static str {
        match self {
            Language::English => "English",
            Language::Chinese => "中文",
            Language::Japanese => "日本語",
            Language::Korean => "한국어",
            Language::Spanish => "Español",
            Language::French => "Français",
            Language::German => "Deutsch",
            Language::Russian => "Русский",
        }
    }
}

/// Translation store
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TranslationStore {
    pub messages: HashMap<String, HashMap<Language, String>>,
}

impl TranslationStore {
    pub fn new() -> Self {
        let mut store = Self {
            messages: HashMap::new(),
        };
        
        // Initialize with default translations
        store.load_default_translations();
        store
    }

    fn load_default_translations(&mut self) {
        // Common messages
        self.add_translation("common.success", Language::English, "Success");
        self.add_translation("common.success", Language::Chinese, "成功");
        self.add_translation("common.success", Language::Japanese, "成功");
        self.add_translation("common.success", Language::Korean, "성공");
        self.add_translation("common.success", Language::Spanish, "Éxito");
        self.add_translation("common.success", Language::French, "Succès");
        self.add_translation("common.success", Language::German, "Erfolg");
        self.add_translation("common.success", Language::Russian, "Успех");

        self.add_translation("common.error", Language::English, "Error");
        self.add_translation("common.error", Language::Chinese, "错误");
        self.add_translation("common.error", Language::Japanese, "エラー");
        self.add_translation("common.error", Language::Korean, "오류");
        self.add_translation("common.error", Language::Spanish, "Error");
        self.add_translation("common.error", Language::French, "Erreur");
        self.add_translation("common.error", Language::German, "Fehler");
        self.add_translation("common.error", Language::Russian, "Ошибка");

        // CLI messages
        self.add_translation("cli.sync_completed", Language::English, "Sync completed successfully");
        self.add_translation("cli.sync_completed", Language::Chinese, "同步成功完成");
        self.add_translation("cli.sync_completed", Language::Japanese, "同期が正常に完了しました");
        self.add_translation("cli.sync_completed", Language::Korean, "동기화가 성공적으로 완료되었습니다");
        self.add_translation("cli.sync_completed", Language::Spanish, "Sincronización completada con éxito");
        self.add_translation("cli.sync_completed", Language::French, "Synchronisation terminée avec succès");
        self.add_translation("cli.sync_completed", Language::German, "Synchronisierung erfolgreich abgeschlossen");
        self.add_translation("cli.sync_completed", Language::Russian, "Синхронизация успешно завершена");

        self.add_translation("cli.file_uploaded", Language::English, "File uploaded successfully");
        self.add_translation("cli.file_uploaded", Language::Chinese, "文件上传成功");
        self.add_translation("cli.file_uploaded", Language::Japanese, "ファイルが正常にアップロードされました");
        self.add_translation("cli.file_uploaded", Language::Korean, "파일이 성공적으로 업로드되었습니다");
        self.add_translation("cli.file_uploaded", Language::Spanish, "Archivo subido con éxito");
        self.add_translation("cli.file_uploaded", Language::French, "Fichier téléchargé avec succès");
        self.add_translation("cli.file_uploaded", Language::German, "Datei erfolgreich hochgeladen");
        self.add_translation("cli.file_uploaded", Language::Russian, "Файл успешно загружен");

        self.add_translation("cli.config_initialized", Language::English, "Configuration initialized");
        self.add_translation("cli.config_initialized", Language::Chinese, "配置已初始化");
        self.add_translation("cli.config_initialized", Language::Japanese, "設定が初期化されました");
        self.add_translation("cli.config_initialized", Language::Korean, "구성이 초기화되었습니다");
        self.add_translation("cli.config_initialized", Language::Spanish, "Configuración inicializada");
        self.add_translation("cli.config_initialized", Language::French, "Configuration initialisée");
        self.add_translation("cli.config_initialized", Language::German, "Konfiguration initialisiert");
        self.add_translation("cli.config_initialized", Language::Russian, "Конфигурация инициализирована");

        // Error messages
        self.add_translation("error.no_config_found", Language::English, "No configuration file found");
        self.add_translation("error.no_config_found", Language::Chinese, "未找到配置文件");
        self.add_translation("error.no_config_found", Language::Japanese, "設定ファイルが見つかりません");
        self.add_translation("error.no_config_found", Language::Korean, "구성 파일을 찾을 수 없습니다");
        self.add_translation("error.no_config_found", Language::Spanish, "No se encontró archivo de configuración");
        self.add_translation("error.no_config_found", Language::French, "Fichier de configuration non trouvé");
        self.add_translation("error.no_config_found", Language::German, "Keine Konfigurationsdatei gefunden");
        self.add_translation("error.no_config_found", Language::Russian, "Файл конфигурации не найден");

        self.add_translation("error.connection_failed", Language::English, "Connection failed");
        self.add_translation("error.connection_failed", Language::Chinese, "连接失败");
        self.add_translation("error.connection_failed", Language::Japanese, "接続に失敗しました");
        self.add_translation("error.connection_failed", Language::Korean, "연결에 실패했습니다");
        self.add_translation("error.connection_failed", Language::Spanish, "Conexión fallida");
        self.add_translation("error.connection_failed", Language::French, "Échec de la connexion");
        self.add_translation("error.connection_failed", Language::German, "Verbindung fehlgeschlagen");
        self.add_translation("error.connection_failed", Language::Russian, "Ошибка подключения");

        self.add_translation("error.authentication_failed", Language::English, "Authentication failed");
        self.add_translation("error.authentication_failed", Language::Chinese, "身份验证失败");
        self.add_translation("error.authentication_failed", Language::Japanese, "認証に失敗しました");
        self.add_translation("error.authentication_failed", Language::Korean, "인증에 실패했습니다");
        self.add_translation("error.authentication_failed", Language::Spanish, "Autenticación fallida");
        self.add_translation("error.authentication_failed", Language::French, "Échec de l'authentification");
        self.add_translation("error.authentication_failed", Language::German, "Authentifizierung fehlgeschlagen");
        self.add_translation("error.authentication_failed", Language::Russian, "Ошибка аутентификации");

        // Additional CLI messages
        self.add_translation("cli.version_info", Language::English, "Astra.nvim Core");
        self.add_translation("cli.version_info", Language::Chinese, "Astra.nvim 核心");
        self.add_translation("cli.version_info", Language::Japanese, "Astra.nvim コア");
        self.add_translation("cli.version_info", Language::Korean, "Astra.nvim 코어");
        self.add_translation("cli.version_info", Language::Spanish, "Astra.nvm Core");
        self.add_translation("cli.version_info", Language::French, "Astra.nvim Core");
        self.add_translation("cli.version_info", Language::German, "Astra.nvim Core");
        self.add_translation("cli.version_info", Language::Russian, "Astra.nvim Core");

        self.add_translation("cli.testing_config", Language::English, "Testing configuration");
        self.add_translation("cli.testing_config", Language::Chinese, "测试配置");
        self.add_translation("cli.testing_config", Language::Japanese, "設定をテスト中");
        self.add_translation("cli.testing_config", Language::Korean, "구성 테스트 중");
        self.add_translation("cli.testing_config", Language::Spanish, "Probando configuración");
        self.add_translation("cli.testing_config", Language::French, "Test de configuration");
        self.add_translation("cli.testing_config", Language::German, "Konfiguration testen");
        self.add_translation("cli.testing_config", Language::Russian, "Тестирование конфигурации");

        self.add_translation("cli.config_loaded", Language::English, "Configuration loaded successfully");
        self.add_translation("cli.config_loaded", Language::Chinese, "配置加载成功");
        self.add_translation("cli.config_loaded", Language::Japanese, "設定が正常に読み込まれました");
        self.add_translation("cli.config_loaded", Language::Korean, "구성이 성공적으로 로드되었습니다");
        self.add_translation("cli.config_loaded", Language::Spanish, "Configuración cargada con éxito");
        self.add_translation("cli.config_loaded", Language::French, "Configuration chargée avec succès");
        self.add_translation("cli.config_loaded", Language::German, "Konfiguration erfolgreich geladen");
        self.add_translation("cli.config_loaded", Language::Russian, "Конфигурация успешно загружена");

        self.add_translation("cli.checking_updates", Language::English, "Checking for updates");
        self.add_translation("cli.checking_updates", Language::Chinese, "检查更新");
        self.add_translation("cli.checking_updates", Language::Japanese, "更新を確認中");
        self.add_translation("cli.checking_updates", Language::Korean, "업데이트 확인 중");
        self.add_translation("cli.checking_updates", Language::Spanish, "Buscando actualizaciones");
        self.add_translation("cli.checking_updates", Language::French, "Vérification des mises à jour");
        self.add_translation("cli.checking_updates", Language::German, "Nach Updates suchen");
        self.add_translation("cli.checking_updates", Language::Russian, "Проверка обновлений");

        self.add_translation("cli.up_to_date", Language::English, "Already up to date");
        self.add_translation("cli.up_to_date", Language::Chinese, "已是最新版本");
        self.add_translation("cli.up_to_date", Language::Japanese, "最新バージョンです");
        self.add_translation("cli.up_to_date", Language::Korean, "최신 버전입니다");
        self.add_translation("cli.up_to_date", Language::Spanish, "Ya está actualizado");
        self.add_translation("cli.up_to_date", Language::French, "Déjà à jour");
        self.add_translation("cli.up_to_date", Language::German, "Bereits auf dem neuesten Stand");
        self.add_translation("cli.up_to_date", Language::Russian, "Уже обновлено");

        self.add_translation("cli.sync_complete", Language::English, "Sync completed successfully");
        self.add_translation("cli.sync_complete", Language::Chinese, "同步成功完成");
        self.add_translation("cli.sync_complete", Language::Japanese, "同期が正常に完了しました");
        self.add_translation("cli.sync_complete", Language::Korean, "동기화가 성공적으로 완료되었습니다");
        self.add_translation("cli.sync_complete", Language::Spanish, "Sincronización completada con éxito");
        self.add_translation("cli.sync_complete", Language::French, "Synchronisation terminée avec succès");
        self.add_translation("cli.sync_complete", Language::German, "Synchronisierung erfolgreich abgeschlossen");
        self.add_translation("cli.sync_complete", Language::Russian, "Синхронизация успешно завершена");

        self.add_translation("cli.sync_failed", Language::English, "Sync failed with {0} errors");
        self.add_translation("cli.sync_failed", Language::Chinese, "同步失败，出现 {0} 个错误");
        self.add_translation("cli.sync_failed", Language::Japanese, "同期に失敗しました。{0} 個のエラーがあります");
        self.add_translation("cli.sync_failed", Language::Korean, "동기화 실패, {0}개 오류 발생");
        self.add_translation("cli.sync_failed", Language::Spanish, "Sincronización fallida con {0} errores");
        self.add_translation("cli.sync_failed", Language::French, "Échec de la synchronisation avec {0} erreurs");
        self.add_translation("cli.sync_failed", Language::German, "Synchronisierung fehlgeschlagen mit {0} Fehlern");
        self.add_translation("cli.sync_failed", Language::Russian, "Синхронизация не удалась с {0} ошибками");

        self.add_translation("cli.upload_operation", Language::English, "Uploading: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::Chinese, "上传中: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::Japanese, "アップロード中: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::Korean, "업로드 중: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::Spanish, "Subiendo: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::French, "Téléchargement: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::German, "Lade hoch: {0} -> {1}");
        self.add_translation("cli.upload_operation", Language::Russian, "Загрузка: {0} -> {1}");

        self.add_translation("cli.download_operation", Language::English, "Downloading: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::Chinese, "下载中: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::Japanese, "ダウンロード中: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::Korean, "다운로드 중: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::Spanish, "Descargando: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::French, "Téléchargement: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::German, "Lade herunter: {0} -> {1}");
        self.add_translation("cli.download_operation", Language::Russian, "Скачивание: {0} -> {1}");

        self.add_translation("cli.pending_operations", Language::English, "Pending operations: {0}");
        self.add_translation("cli.pending_operations", Language::Chinese, "待处理操作: {0}");
        self.add_translation("cli.pending_operations", Language::Japanese, "保留中の操作: {0}");
        self.add_translation("cli.pending_operations", Language::Korean, "보류 중인 작업: {0}");
        self.add_translation("cli.pending_operations", Language::Spanish, "Operaciones pendientes: {0}");
        self.add_translation("cli.pending_operations", Language::French, "Opérations en attente: {0}");
        self.add_translation("cli.pending_operations", Language::German, "Ausstehende Operationen: {0}");
        self.add_translation("cli.pending_operations", Language::Russian, "Ожидающие операции: {0}");

        // Additional error messages
        self.add_translation("error.upload_failed", Language::English, "Upload failed");
        self.add_translation("error.upload_failed", Language::Chinese, "上传失败");
        self.add_translation("error.upload_failed", Language::Japanese, "アップロードに失敗しました");
        self.add_translation("error.upload_failed", Language::Korean, "업로드 실패");
        self.add_translation("error.upload_failed", Language::Spanish, "Error al subir");
        self.add_translation("error.upload_failed", Language::French, "Échec du téléchargement");
        self.add_translation("error.upload_failed", Language::German, "Hochladen fehlgeschlagen");
        self.add_translation("error.upload_failed", Language::Russian, "Ошибка загрузки");

        self.add_translation("cli.config_error", Language::English, "Configuration error: {0}");
        self.add_translation("cli.config_error", Language::Chinese, "配置错误: {0}");
        self.add_translation("cli.config_error", Language::Japanese, "設定エラー: {0}");
        self.add_translation("cli.config_error", Language::Korean, "구성 오류: {0}");
        self.add_translation("cli.config_error", Language::Spanish, "Error de configuración: {0}");
        self.add_translation("cli.config_error", Language::French, "Erreur de configuration: {0}");
        self.add_translation("cli.config_error", Language::German, "Konfigurationsfehler: {0}");
        self.add_translation("cli.config_error", Language::Russian, "Ошибка конфигурации: {0}");
    }

    fn add_translation(&mut self, key: &str, language: Language, message: &str) {
        self.messages
            .entry(key.to_string())
            .or_insert_with(HashMap::new)
            .insert(language, message.to_string());
    }

    pub fn get_translation(&self, key: &str, language: &Language) -> Option<&String> {
        self.messages
            .get(key)
            .and_then(|translations| translations.get(language))
    }

    pub fn get_translation_or_fallback(&self, key: &str, language: &Language) -> String {
        self.get_translation(key, language)
            .or_else(|| self.get_translation(key, &Language::English))
            .map(|s| s.clone())
            .unwrap_or_else(|| key.to_string())
    }

    pub fn add_custom_translation(&mut self, key: &str, language: Language, message: String) {
        self.add_translation(key, language, &message);
    }

    pub fn load_from_file(&mut self, file_path: &str) -> Result<(), Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(file_path)?;
        let custom_store: TranslationStore = serde_json::from_str(&content)?;

        for (key, translations) in custom_store.messages {
            for (language, message) in translations {
                self.add_custom_translation(&key, language, message);
            }
        }

        Ok(())
    }

    pub fn save_to_file(&self, file_path: &str) -> Result<(), Box<dyn std::error::Error>> {
        let content = serde_json::to_string_pretty(self)?;
        std::fs::write(file_path, content)?;
        Ok(())
    }
}

/// Global translation store
static mut TRANSLATION_STORE: Option<TranslationStore> = None;

/// Initialize translation store
pub fn init_translations() {
    unsafe {
        if TRANSLATION_STORE.is_none() {
            TRANSLATION_STORE = Some(TranslationStore::new());
        }
    }
}

/// Get translation store
pub fn get_translation_store() -> &'static TranslationStore {
    unsafe {
        if TRANSLATION_STORE.is_none() {
            init_translations();
        }
        TRANSLATION_STORE.as_ref().unwrap()
    }
}

/// Get translation for a key in the specified language
pub fn t(key: &str, language: &Language) -> String {
    get_translation_store().get_translation_or_fallback(key, language)
}

/// Get translation for a key in the default language
pub fn t_default(key: &str) -> String {
    t(key, &Language::default())
}

/// Format translation with arguments
pub fn t_format(key: &str, language: &Language, args: &[&str]) -> String {
    let template = t(key, language);
    let mut result = template;
    
    for (i, arg) in args.iter().enumerate() {
        result = result.replace(&format!("{{{}}}", i), arg);
    }
    
    result
}

/// Get all supported languages
pub fn get_supported_languages() -> Vec<Language> {
    vec![
        Language::English,
        Language::Chinese,
        Language::Japanese,
        Language::Korean,
        Language::Spanish,
        Language::French,
        Language::German,
        Language::Russian,
    ]
}

/// Get system language
pub fn get_system_language() -> Language {
    Language::default()
}

/// Detect language from environment
pub fn detect_language() -> Language {
    // Check environment variables
    if let Ok(lang) = env::var("ASTRA_LANGUAGE") {
        if let Some(detected) = Language::from_str(&lang) {
            return detected;
        }
    }
    
    if let Ok(lang) = env::var("LANG") {
        if let Some(detected) = Language::from_str(&lang.split('_').next().unwrap_or("")) {
            return detected;
        }
    }
    
    // Default to English
    Language::English
}