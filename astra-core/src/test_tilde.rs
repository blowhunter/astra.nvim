#[cfg(test)]
mod tests {
    use crate::config::ConfigReader;

    #[test]
    fn test_expand_tilde_remote() {
        // Test root user
        assert_eq!(
            ConfigReader::expand_tilde_remote("~/test", "root"),
            "/root/test"
        );
        assert_eq!(ConfigReader::expand_tilde_remote("~", "root"), "/root");

        // Test regular user
        assert_eq!(
            ConfigReader::expand_tilde_remote("~/test", "testuser"),
            "/home/testuser/test"
        );
        assert_eq!(
            ConfigReader::expand_tilde_remote("~", "testuser"),
            "/home/testuser"
        );

        // Test absolute path (no change)
        assert_eq!(
            ConfigReader::expand_tilde_remote("/absolute/path", "testuser"),
            "/absolute/path"
        );

        // Test path with tilde in the middle (no change)
        assert_eq!(
            ConfigReader::expand_tilde_remote("/path/~test", "testuser"),
            "/path/~test"
        );
    }
}
