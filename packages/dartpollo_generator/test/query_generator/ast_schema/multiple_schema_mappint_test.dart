import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:dartpollo_generator/builder.dart';
import 'package:dartpollo_generator/generator/data/data.dart';
import 'package:dartpollo_generator/generator/data/enum_value_definition.dart';
import 'package:test/test.dart';

void main() {
  group('Multiple schema mapping', () {
    test(
      'Should search for definitions in correct schema',
      () {
        final anotherBuilder = graphQLQueryBuilder(
          const BuilderOptions({
            'generate_helpers': true,
            'schema_mapping': [
              {
                'schema': 'schemaA.graphql',
                'queries_glob': 'queries/queryA.graphql',
                'output': 'lib/outputA.graphql.dart',
                'naming_scheme': 'pathedWithFields',
              },
              {
                'schema': 'schemaB.graphql',
                'queries_glob': 'queries/queryB.graphql',
                'output': 'lib/outputB.graphql.dart',
                'naming_scheme': 'pathedWithFields',
              },
            ],
          }),
        );

        var count = 0;
        anotherBuilder.onBuild = expectAsync1((definition) {
          log.fine(definition);
          // Create a copy of the definition without schemaMap for comparison
          final definitionForComparison = LibraryDefinition(
            basename: definition.basename,
            queries: definition.queries,
            customImports: definition.customImports,
          );

          if (count == 0) {
            expect(definitionForComparison, libraryDefinitionA);
          }

          if (count == 1) {
            expect(definitionForComparison, libraryDefinitionB);
          }

          count++;
        }, count: 2);

        return testBuilder(
          anotherBuilder,
          {
            'a|schemaA.graphql': schemaA,
            'a|schemaB.graphql': schemaB,
            'a|queries/queryA.graphql': queryA,
            'a|queries/queryB.graphql': queryB,
          },
          outputs: {
            'a|lib/outputA.graphql.dart':
                anything, // Use 'anything' matcher to accept any output
            'a|lib/outputB.graphql.dart':
                anything, // Use 'anything' matcher to accept any output
          },
          onLog: print,
        );
      },
    );
  });
}

const schemaA = r'''
  schema {
    query: Query
  }

  type Query {
      articles: [Article!]
  }

  type Article {
    id: ID!
    title: String!
    articleType: ArticleType!
  }

  enum ArticleType {
    NEWS
    TUTORIAL
  }
''';

const schemaB = r'''
  schema {
    query: Query
  }

  type Query {
      repositories(notificationTypes: [NotificationOptionInput]): [Repository!]
  }

  type Repository {
    id: ID!
    title: String!
    privacy: Privacy!
    status: Status!
  }

  enum Privacy {
    PRIVATE
    PUBLIC
  }

  enum Status {
    ARCHIVED
    NORMAL
  }

  input NotificationOptionInput {
    type: NotificationType
    enabled: Boolean
  }

  enum NotificationType {
    ACTIVITY_MESSAGE
    ACTIVITY_REPLY
    FOLLOWING
    ACTIVITY_MENTION
  }
''';

const queryA = r'''
  query BrowseArticles {
    articles {
        id
        title
        articleType
    }
  }
''';

const queryB = r'''
  query BrowseRepositories($notificationTypes: [NotificationOptionInput]) {
    repositories(notificationTypes: $notificationTypes) {
        id
        title
        privacy
        status
    }
  }
''';

final LibraryDefinition libraryDefinitionA = LibraryDefinition(
  basename: r'outputA.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'BrowseArticles$_Query'),
      operationName: r'BrowseArticles',
      classes: [
        EnumDefinition(
          name: EnumName(name: r'ArticleType'),
          values: [
            EnumValueDefinition(name: EnumValueName(name: r'NEWS')),
            EnumValueDefinition(name: EnumValueName(name: r'TUTORIAL')),
            EnumValueDefinition(name: EnumValueName(name: r'UNKNOWN')),
          ],
        ),
        ClassDefinition(
          name: ClassName(name: r'BrowseArticles$_Query$_articles'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'id'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'title'),
            ),
            ClassProperty(
              type: TypeName(name: r'ArticleType', isNonNull: true),
              name: const ClassPropertyName(name: r'articleType'),
              annotations: const [
                r'JsonKey(unknownEnumValue: ArticleType.unknown)',
              ],
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'BrowseArticles$_Query'),
          properties: [
            ClassProperty(
              type: ListOfTypeName(
                typeName: TypeName(
                  name: r'BrowseArticles$_Query$_articles',
                  isNonNull: true,
                ),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'articles'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
      ],
      generateHelpers: true,
    ),
  ],
);

final libraryDefinitionB = LibraryDefinition(
  basename: r'outputB.graphql',
  queries: [
    QueryDefinition(
      name: QueryName(name: r'BrowseRepositories$_Query'),
      operationName: r'BrowseRepositories',
      classes: [
        EnumDefinition(
          name: EnumName(name: r'Privacy'),
          values: [
            EnumValueDefinition(name: EnumValueName(name: r'PRIVATE')),
            EnumValueDefinition(name: EnumValueName(name: r'PUBLIC')),
            EnumValueDefinition(name: EnumValueName(name: r'UNKNOWN')),
          ],
        ),
        EnumDefinition(
          name: EnumName(name: r'Status'),
          values: [
            EnumValueDefinition(name: EnumValueName(name: r'ARCHIVED')),
            EnumValueDefinition(name: EnumValueName(name: r'NORMAL')),
            EnumValueDefinition(name: EnumValueName(name: r'UNKNOWN')),
          ],
        ),
        EnumDefinition(
          name: EnumName(name: r'NotificationType'),
          values: [
            EnumValueDefinition(name: EnumValueName(name: r'ACTIVITY_MESSAGE')),
            EnumValueDefinition(name: EnumValueName(name: r'ACTIVITY_REPLY')),
            EnumValueDefinition(name: EnumValueName(name: r'FOLLOWING')),
            EnumValueDefinition(name: EnumValueName(name: r'ACTIVITY_MENTION')),
            EnumValueDefinition(name: EnumValueName(name: r'UNKNOWN')),
          ],
        ),
        ClassDefinition(
          name: ClassName(name: r'BrowseRepositories$_Query$_repositories'),
          properties: [
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'id'),
            ),
            ClassProperty(
              type: DartTypeName(name: r'String', isNonNull: true),
              name: const ClassPropertyName(name: r'title'),
            ),
            ClassProperty(
              type: TypeName(name: r'Privacy', isNonNull: true),
              name: const ClassPropertyName(name: r'privacy'),
              annotations: const [
                r'JsonKey(unknownEnumValue: Privacy.unknown)',
              ],
            ),
            ClassProperty(
              type: TypeName(name: r'Status', isNonNull: true),
              name: const ClassPropertyName(name: r'status'),
              annotations: const [r'JsonKey(unknownEnumValue: Status.unknown)'],
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'BrowseRepositories$_Query'),
          properties: [
            ClassProperty(
              type: ListOfTypeName(
                typeName: TypeName(
                  name: r'BrowseRepositories$_Query$_repositories',
                  isNonNull: true,
                ),
                isNonNull: false,
              ),
              name: const ClassPropertyName(name: r'repositories'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
        ),
        ClassDefinition(
          name: ClassName(name: r'NotificationOptionInput'),
          properties: [
            ClassProperty(
              type: TypeName(name: r'NotificationType'),
              name: const ClassPropertyName(name: r'type'),
              annotations: const [
                r'JsonKey(unknownEnumValue: NotificationType.unknown)',
              ],
            ),
            ClassProperty(
              type: DartTypeName(name: r'bool'),
              name: const ClassPropertyName(name: r'enabled'),
            ),
          ],
          typeNameField: const ClassPropertyName(name: r'__typename'),
          isInput: true,
        ),
      ],
      inputs: [
        QueryInput(
          type: ListOfTypeName(
            typeName: TypeName(name: r'NotificationOptionInput'),
            isNonNull: false,
          ),
          name: const QueryInputName(name: r'notificationTypes'),
        ),
      ],
      generateHelpers: true,
    ),
  ],
);
