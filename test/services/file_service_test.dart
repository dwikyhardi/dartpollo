import 'dart:io';

import 'package:dartpollo/services/file_service.dart';
import 'package:test/test.dart';

void main() {
  group('FileService', () {
    group('extractBasename', () {
      test('should extract basename without extension from simple path', () {
        expect(FileService.extractBasename('file.dart'), equals('file'));
        expect(FileService.extractBasename('test.graphql'), equals('test'));
        expect(
          FileService.extractBasename('query.graphql.dart'),
          equals('query.graphql'),
        );
      });

      test('should extract basename from absolute path', () {
        expect(
          FileService.extractBasename('/path/to/file.dart'),
          equals('file'),
        );
        expect(
          FileService.extractBasename('/usr/local/bin/app.exe'),
          equals('app'),
        );
      });

      test('should extract basename from relative path', () {
        expect(FileService.extractBasename('./file.dart'), equals('file'));
        expect(
          FileService.extractBasename('../parent/file.dart'),
          equals('file'),
        );
        expect(
          FileService.extractBasename('nested/deep/file.dart'),
          equals('file'),
        );
      });

      test('should handle files without extension', () {
        expect(FileService.extractBasename('README'), equals('README'));
        expect(
          FileService.extractBasename('/path/to/LICENSE'),
          equals('LICENSE'),
        );
      });

      test('should handle files with multiple dots', () {
        expect(
          FileService.extractBasename('file.test.dart'),
          equals('file.test'),
        );
        expect(
          FileService.extractBasename('config.local.json'),
          equals('config.local'),
        );
        expect(
          FileService.extractBasename('archive.tar.gz'),
          equals('archive.tar'),
        );
      });

      test('should handle Windows-style paths', () {
        // On non-Windows platforms, backslashes are treated as part of the filename
        if (Platform.isWindows) {
          expect(
            FileService.extractBasename('C:\\Users\\file.dart'),
            equals('file'),
          );
          expect(
            FileService.extractBasename('..\\parent\\file.dart'),
            equals('file'),
          );
        } else {
          // On Unix-like systems, backslashes are part of the filename
          expect(
            FileService.extractBasename('C:\\Users\\file.dart'),
            equals('C:\\Users\\file'),
          );
          expect(
            FileService.extractBasename('..\\parent\\file.dart'),
            equals('..\\parent\\file'),
          );
        }
      });

      test('should handle edge cases with dots', () {
        expect(FileService.extractBasename('.hidden'), equals('.hidden'));
        expect(FileService.extractBasename('.hidden.dart'), equals('.hidden'));
        expect(FileService.extractBasename('..'), equals('..'));
        expect(FileService.extractBasename('.'), equals('.'));
      });

      test('should throw ArgumentError for empty path', () {
        expect(
          () => FileService.extractBasename(''),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              equals('Path cannot be empty'),
            ),
          ),
        );
      });
    });

    group('extractPath', () {
      test('should extract directory path from absolute path', () {
        expect(
          FileService.extractPath('/path/to/file.dart'),
          equals('/path/to'),
        );
        expect(
          FileService.extractPath('/usr/local/bin/app'),
          equals('/usr/local/bin'),
        );
        expect(FileService.extractPath('/file.dart'), equals('/'));
      });

      test('should extract directory path from relative path', () {
        expect(FileService.extractPath('path/to/file.dart'), equals('path/to'));
        expect(FileService.extractPath('./file.dart'), equals('.'));
        expect(FileService.extractPath('../file.dart'), equals('..'));
        expect(
          FileService.extractPath('nested/deep/file.dart'),
          equals('nested/deep'),
        );
      });

      test('should return current directory for file in current directory', () {
        expect(FileService.extractPath('file.dart'), equals('.'));
        expect(FileService.extractPath('README'), equals('.'));
      });

      test('should handle Windows-style paths', () {
        // On non-Windows platforms, backslashes are treated as part of the filename
        if (Platform.isWindows) {
          expect(
            FileService.extractPath('C:\\Users\\Documents\\file.dart'),
            equals('C:\\Users\\Documents'),
          );
          expect(
            FileService.extractPath('..\\parent\\file.dart'),
            equals('..\\parent'),
          );
        } else {
          // On Unix-like systems, backslashes are part of the filename, so these are treated as single files
          expect(
            FileService.extractPath('C:\\Users\\Documents\\file.dart'),
            equals('.'),
          );
          expect(FileService.extractPath('..\\parent\\file.dart'), equals('.'));
        }
      });

      test('should handle root directory files', () {
        expect(FileService.extractPath('/file.dart'), equals('/'));
      });

      test('should handle complex nested paths', () {
        expect(
          FileService.extractPath('a/b/c/d/e/file.dart'),
          equals('a/b/c/d/e'),
        );
        expect(
          FileService.extractPath('./nested/./deep/../file.dart'),
          equals('./nested/./deep/..'),
        );
      });

      test('should throw ArgumentError for empty path', () {
        expect(
          () => FileService.extractPath(''),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              equals('Path cannot be empty'),
            ),
          ),
        );
      });
    });

    group('validatePath', () {
      test('should pass validation for valid relative paths', () {
        expect(() => FileService.validatePath('file.dart'), returnsNormally);
        expect(() => FileService.validatePath('./file.dart'), returnsNormally);
        expect(() => FileService.validatePath('../file.dart'), returnsNormally);
        expect(
          () => FileService.validatePath('nested/path/file.dart'),
          returnsNormally,
        );
      });

      test(
        'should pass validation for valid absolute paths with existing parent',
        () {
          // Create a temporary directory to test with
          final tempDir = Directory.systemTemp.createTempSync(
            'file_service_test',
          );
          final testPath = '${tempDir.path}/test_file.dart';

          expect(() => FileService.validatePath(testPath), returnsNormally);

          // Clean up
          tempDir.deleteSync(recursive: true);
        },
      );

      test('should throw ArgumentError for empty path', () {
        expect(
          () => FileService.validatePath(''),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              equals('Path cannot be empty'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for path with null character', () {
        expect(
          () => FileService.validatePath('file\x00.dart'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              equals('Path contains null character'),
            ),
          ),
        );
      });

      test(
        'should throw FileSystemException for absolute path with non-existent parent',
        () {
          const nonExistentPath = '/this/path/should/not/exist/file.dart';

          expect(
            () => FileService.validatePath(nonExistentPath),
            throwsA(
              isA<FileSystemException>().having(
                (e) => e.message,
                'message',
                equals('Parent directory does not exist'),
              ),
            ),
          );
        },
      );

      test('should handle paths with special characters', () {
        expect(
          () => FileService.validatePath('file with spaces.dart'),
          returnsNormally,
        );
        expect(
          () => FileService.validatePath('file-with-dashes.dart'),
          returnsNormally,
        );
        expect(
          () => FileService.validatePath('file_with_underscores.dart'),
          returnsNormally,
        );
        expect(
          () => FileService.validatePath('file.with.dots.dart'),
          returnsNormally,
        );
      });

      test('should handle Unicode characters in paths', () {
        expect(() => FileService.validatePath('файл.dart'), returnsNormally);
        expect(() => FileService.validatePath('文件.dart'), returnsNormally);
        expect(
          () => FileService.validatePath('🚀rocket.dart'),
          returnsNormally,
        );
      });
    });

    group('normalizePath', () {
      test('should normalize relative path components', () {
        expect(FileService.normalizePath('./file.dart'), equals('file.dart'));
        expect(
          FileService.normalizePath('./path/../file.dart'),
          equals('file.dart'),
        );
        expect(
          FileService.normalizePath('path/./file.dart'),
          equals('path/file.dart'),
        );
        expect(
          FileService.normalizePath('path/../other/file.dart'),
          equals('other/file.dart'),
        );
      });

      test('should normalize redundant separators', () {
        expect(
          FileService.normalizePath('path//to//file.dart'),
          equals('path/to/file.dart'),
        );
        expect(
          FileService.normalizePath('/path///to/file.dart'),
          equals('/path/to/file.dart'),
        );
      });

      test('should handle complex path normalization', () {
        expect(
          FileService.normalizePath('./a/../b/./c/../d/file.dart'),
          equals('b/d/file.dart'),
        );
        expect(
          FileService.normalizePath('/a/b/../c/./d/../e/file.dart'),
          equals('/a/c/e/file.dart'),
        );
      });

      test('should preserve absolute vs relative nature', () {
        expect(FileService.normalizePath('/absolute/path'), startsWith('/'));
        expect(
          FileService.normalizePath('relative/path'),
          isNot(startsWith('/')),
        );
      });

      test('should handle edge cases', () {
        expect(FileService.normalizePath('.'), equals('.'));
        expect(FileService.normalizePath('..'), equals('..'));
        expect(FileService.normalizePath('./'), equals('.'));
        expect(FileService.normalizePath('../'), equals('..'));
      });

      test('should throw ArgumentError for empty path', () {
        expect(
          () => FileService.normalizePath(''),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              equals('Path cannot be empty'),
            ),
          ),
        );
      });
    });

    group('joinPath', () {
      test('should join simple path components', () {
        expect(
          FileService.joinPath(['path', 'to', 'file.dart']),
          equals('path/to/file.dart'),
        );
        expect(FileService.joinPath(['a', 'b', 'c']), equals('a/b/c'));
      });

      test('should handle single component', () {
        expect(FileService.joinPath(['file.dart']), equals('file.dart'));
      });

      test('should handle absolute path components', () {
        expect(
          FileService.joinPath(['/root', 'path', 'file.dart']),
          equals('/root/path/file.dart'),
        );
      });

      test('should handle empty components', () {
        expect(
          FileService.joinPath(['path', '', 'file.dart']),
          equals('path/file.dart'),
        );
        expect(
          FileService.joinPath(['', 'path', 'file.dart']),
          equals('path/file.dart'),
        );
      });

      test('should handle relative components', () {
        expect(
          FileService.joinPath(['.', 'path', 'file.dart']),
          equals('./path/file.dart'),
        );
        expect(
          FileService.joinPath(['..', 'path', 'file.dart']),
          equals('../path/file.dart'),
        );
      });

      test('should handle components with separators', () {
        expect(
          FileService.joinPath(['path/to', 'file.dart']),
          equals('path/to/file.dart'),
        );
        expect(
          FileService.joinPath(['path', 'to/deep', 'file.dart']),
          equals('path/to/deep/file.dart'),
        );
      });

      test('should throw ArgumentError for empty components list', () {
        expect(
          () => FileService.joinPath([]),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              equals('Path components cannot be empty'),
            ),
          ),
        );
      });
    });

    group('isAbsolute', () {
      test('should identify absolute paths correctly', () {
        expect(FileService.isAbsolute('/path/to/file'), isTrue);
        expect(FileService.isAbsolute('/file'), isTrue);
        expect(FileService.isAbsolute('/'), isTrue);
      });

      test('should identify relative paths correctly', () {
        expect(FileService.isAbsolute('path/to/file'), isFalse);
        expect(FileService.isAbsolute('./file'), isFalse);
        expect(FileService.isAbsolute('../file'), isFalse);
        expect(FileService.isAbsolute('file'), isFalse);
      });

      test('should handle Windows-style absolute paths', () {
        // Note: This behavior depends on the platform
        expect(
          FileService.isAbsolute('C:\\path\\to\\file'),
          equals(Platform.isWindows),
        );
        expect(FileService.isAbsolute('D:\\file'), equals(Platform.isWindows));
      });

      test('should handle edge cases', () {
        expect(FileService.isAbsolute(''), isFalse);
        expect(FileService.isAbsolute('.'), isFalse);
        expect(FileService.isAbsolute('..'), isFalse);
      });
    });

    group('getExtension', () {
      test('should extract file extensions correctly', () {
        expect(FileService.getExtension('file.dart'), equals('.dart'));
        expect(FileService.getExtension('test.graphql'), equals('.graphql'));
        expect(FileService.getExtension('archive.tar.gz'), equals('.gz'));
      });

      test('should handle files without extension', () {
        expect(FileService.getExtension('README'), equals(''));
        expect(FileService.getExtension('LICENSE'), equals(''));
      });

      test('should handle hidden files', () {
        expect(FileService.getExtension('.hidden'), equals(''));
        expect(FileService.getExtension('.hidden.dart'), equals('.dart'));
      });

      test('should handle paths with directories', () {
        expect(FileService.getExtension('/path/to/file.dart'), equals('.dart'));
        expect(FileService.getExtension('nested/deep/file.js'), equals('.js'));
      });

      test('should handle edge cases', () {
        expect(FileService.getExtension(''), equals(''));
        expect(FileService.getExtension('.'), equals(''));
        expect(FileService.getExtension('..'), equals(''));
        expect(FileService.getExtension('file.'), equals('.'));
      });

      test('should handle multiple extensions', () {
        expect(FileService.getExtension('file.test.dart'), equals('.dart'));
        expect(FileService.getExtension('config.local.json'), equals('.json'));
        expect(FileService.getExtension('backup.2023.tar.gz'), equals('.gz'));
      });
    });

    group('error cases and edge conditions', () {
      test('should handle very long paths', () {
        final longPath = 'a/' * 100 + 'file.dart';
        expect(() => FileService.extractBasename(longPath), returnsNormally);
        expect(() => FileService.extractPath(longPath), returnsNormally);
        expect(() => FileService.normalizePath(longPath), returnsNormally);
      });

      test('should handle paths with only separators', () {
        expect(FileService.extractPath('/'), equals('/'));
        expect(FileService.normalizePath('//'), equals('/'));
      });

      test('should handle paths with trailing separators', () {
        expect(FileService.extractBasename('path/to/file/'), equals('file'));
        expect(FileService.extractPath('path/to/file/'), equals('path/to'));
      });

      test('should handle case sensitivity appropriately', () {
        expect(FileService.extractBasename('File.DART'), equals('File'));
        expect(FileService.getExtension('File.DART'), equals('.DART'));
      });

      test('should handle paths with spaces and special characters', () {
        const specialPath = 'path with spaces/file-name_test.dart';
        expect(
          FileService.extractBasename(specialPath),
          equals('file-name_test'),
        );
        expect(
          FileService.extractPath(specialPath),
          equals('path with spaces'),
        );
        expect(FileService.getExtension(specialPath), equals('.dart'));
      });

      test('should handle network paths and UNC paths on Windows', () {
        if (Platform.isWindows) {
          expect(
            () => FileService.extractBasename('\\\\server\\share\\file.dart'),
            returnsNormally,
          );
          expect(
            () => FileService.extractPath('\\\\server\\share\\file.dart'),
            returnsNormally,
          );
        }
      });

      test('should handle symbolic links and junctions gracefully', () {
        // These should not throw errors even if the target doesn't exist
        expect(
          () => FileService.extractBasename('symlink/file.dart'),
          returnsNormally,
        );
        expect(
          () => FileService.extractPath('symlink/file.dart'),
          returnsNormally,
        );
      });
    });
  });
}
