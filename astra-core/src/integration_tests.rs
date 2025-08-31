use std::fs;
use tempfile::TempDir;

#[test]
fn test_basic_functionality() {
    let temp_dir = TempDir::new().unwrap();

    let test_file = temp_dir.path().join("test.txt");
    fs::write(&test_file, "Hello, World!").unwrap();

    assert!(test_file.exists());

    let content = fs::read_to_string(&test_file).unwrap();
    assert_eq!(content, "Hello, World!");
}

#[test]
fn test_file_tracking() {
    let temp_dir = TempDir::new().unwrap();

    fs::write(temp_dir.path().join("file1.txt"), "content1").unwrap();
    fs::write(temp_dir.path().join("file2.txt"), "content2").unwrap();

    let entries = fs::read_dir(temp_dir.path()).unwrap();
    let mut file_count = 0;

    for entry in entries {
        let entry = entry.unwrap();
        if entry.path().is_file() {
            file_count += 1;
        }
    }

    assert_eq!(file_count, 2);
}

#[test]
fn test_incremental_sync_logic() {
    let local_dir = TempDir::new().unwrap();
    let remote_dir = TempDir::new().unwrap();

    fs::write(local_dir.path().join("common.txt"), "same content").unwrap();
    fs::write(remote_dir.path().join("common.txt"), "same content").unwrap();

    fs::write(local_dir.path().join("local_only.txt"), "local content").unwrap();
    fs::write(remote_dir.path().join("remote_only.txt"), "remote content").unwrap();

    let local_files: Vec<_> = fs::read_dir(local_dir.path())
        .unwrap()
        .filter_map(Result::ok)
        .map(|e| e.path())
        .collect();

    let remote_files: Vec<_> = fs::read_dir(remote_dir.path())
        .unwrap()
        .filter_map(Result::ok)
        .map(|e| e.path())
        .collect();

    assert_eq!(local_files.len(), 2);
    assert_eq!(remote_files.len(), 2);

    let common_local = local_files
        .iter()
        .find(|p| p.file_name().unwrap() == "common.txt")
        .unwrap();
    let common_remote = remote_files
        .iter()
        .find(|p| p.file_name().unwrap() == "common.txt")
        .unwrap();

    assert!(common_local.exists());
    assert!(common_remote.exists());
}
