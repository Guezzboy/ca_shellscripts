import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:collection_app/core/services/isbn_lookup_service.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late IsbnLookupService service;

  setUp(() {
    dio = MockDio();
    service = IsbnLookupService(dio: dio);
  });

  group('IsbnLookupService', () {
    test('lookupIsbn — parses Open Library response', () async {
      when(() => dio.get('https://openlibrary.org/isbn/9780141036144.json'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                data: {
                  'title': '1984',
                  'authors': [
                    {'name': 'George Orwell'}
                  ],
                  'publishers': ['Penguin'],
                  'publish_date': '2008',
                  'number_of_pages': 368,
                  'covers': [12345],
                },
              ));

      final book = await service.lookupIsbn('9780141036144');

      expect(book, isNotNull);
      expect(book!.title, '1984');
      expect(book.authors, ['George Orwell']);
      expect(book.publisher, 'Penguin');
      expect(book.year, '2008');
      expect(book.pageCount, 368);
      expect(book.coverUrl, 'https://covers.openlibrary.org/b/id/12345-M.jpg');
    });

    test('lookupIsbn — falls back to Google Books when Open Library fails',
        () async {
      when(() => dio.get('https://openlibrary.org/isbn/9781234567890.json'))
          .thenThrow(Exception('not found'));
      when(() => dio.get(
            'https://www.googleapis.com/books/v1/volumes',
            queryParameters: {'q': 'isbn:9781234567890'},
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                data: {
                  'items': [
                    {
                      'volumeInfo': {
                        'title': 'Test Book',
                        'authors': ['John Doe'],
                        'publisher': 'TestPub',
                        'publishedDate': '2020',
                        'imageLinks': {
                          'thumbnail': 'http://example.com/thumb.jpg'
                        },
                      }
                    }
                  ]
                },
              ));

      final book = await service.lookupIsbn('9781234567890');

      expect(book, isNotNull);
      expect(book!.title, 'Test Book');
      expect(book.authors, ['John Doe']);
      expect(book.publisher, 'TestPub');
      expect(book.year, '2020');
      expect(book.coverUrl, 'http://example.com/thumb.jpg');
    });

    test('lookupIsbn — returns null when both sources fail', () async {
      when(() => dio.get('https://openlibrary.org/isbn/9780000000000.json'))
          .thenThrow(Exception('not found'));
      when(() => dio.get(
            'https://www.googleapis.com/books/v1/volumes',
            queryParameters: {'q': 'isbn:9780000000000'},
          )).thenThrow(Exception('not found'));

      final book = await service.lookupIsbn('9780000000000');

      expect(book, isNull);
    });

    test('lookupIsbn — returns null for empty ISBN after cleaning', () async {
      final book = await service.lookupIsbn('---');
      expect(book, isNull);
    });

    test('lookupIsbn — strips non-digit/non-X characters from ISBN',
        () async {
      when(() => dio.get('https://openlibrary.org/isbn/9780141036144.json'))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: ''),
                data: {'title': 'Test'},
              ));

      final book = await service.lookupIsbn('978-0-14-103614-4');

      expect(book, isNotNull);
      expect(book!.title, 'Test');
    });
  });

  group('BookData', () {
    test('year — extracts 4-digit year from publishDate', () {
      const book = BookData(publishDate: '2008-06-01');
      expect(book.year, '2008');
    });

    test('year — returns null when no date', () {
      const book = BookData(publishDate: null);
      expect(book.year, isNull);
    });

    test('authorString — joins authors with comma', () {
      const book = BookData(authors: ['Orwell', 'Huxley']);
      expect(book.authorString, 'Orwell, Huxley');
    });

    test('authorString — empty string for no authors', () {
      const book = BookData();
      expect(book.authorString, '');
    });
  });
}
