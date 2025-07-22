# FAQ & Troubleshooting

## General

**Q: What is Namida Sync?**  
A: A cross-platform backup and restore companion for the Namida music player, supporting Google Drive sync.

**Q: What platforms are supported?**  
A: Android and Windows. Cross-platform restore is supported.

## Setup & Usage


**Q: Why can't I see my backup/music folders?**  
A: Check permissions and folder paths. Re-pick folders if needed.

**Q: Restore/backup fails with a permission error.**  
A: Grant storage/media permissions in your device settings.

**Q: My backup/restore is slow or interrupted.**  
A: Use a stable internet connection. Large libraries may take time.

## Google Drive

**Q: Why does Namida Sync use Google Drive for backup and restore?**  
A: Google Drive is widely available, secure, and offers **generous free storage**. It allows you to access your backups from any device, supports large files, and integrates well with both Android and Windows. Using Google Drive also means you don’t need to set up your own server or pay for extra services, unless your music liberary size goes beyond free storage limit (15 GB per Google Account).

**Q: Google sign-in fails or times out.**  
A: Try signing out and back in. Check your internet connection.

**Q: Files are missing after restore.**  
A: Check the manifest and ensure all files were backed up. Try restoring again.

## More Help

- Open an issue on GitHub for bugs or feature requests.
- See the full documentation in the [docs/README.md](./README.md) folder.

## Development (For Developers)

**Q: How do I run tests?**  
A: See [docs/testing.md](testing.md).

**Q: How do I contribute?**  
A: See [CONTRIBUTING.md](../CONTRIBUTING.md).

**Q: How do I set up secrets?**  
A: See [docs/secrets.md](secrets.md).
