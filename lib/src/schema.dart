import 'package:gql/ast.dart';
import 'package:gql/language.dart';

class Schema {
  Schema({
    required this.queryType,
    required this.mutationType,
    required this.subscriptionType,
    required this.types,
    required this.interfaces,
    required this.unions,
    required this.enums,
    required this.inputs,
    required this.scalars,
  });

  final String? queryType;
  final String? mutationType;
  final String? subscriptionType;
  final Map<String, ObjectTypeDefinitionNode> types;
  final Map<String, InterfaceTypeDefinitionNode> interfaces;
  final Map<String, UnionTypeDefinitionNode> unions;
  final Map<String, EnumTypeDefinitionNode> enums;
  final Map<String, InputObjectTypeDefinitionNode> inputs;
  final Set<String> scalars;

  static Schema parse(String source) {
    final doc = parseString(source);
    String? query;
    String? mutation;
    String? subscription;
    for (final def in doc.definitions) {
      if (def is SchemaDefinitionNode) {
        for (final op in def.operationTypes) {
          switch (op.operation) {
            case OperationType.query:
              query = op.type.name.value;
              break;
            case OperationType.mutation:
              mutation = op.type.name.value;
              break;
            case OperationType.subscription:
              subscription = op.type.name.value;
              break;
          }
        }
      }
    }

    final objects = <String, ObjectTypeDefinitionNode>{};
    final interfaces = <String, InterfaceTypeDefinitionNode>{};
    final unions = <String, UnionTypeDefinitionNode>{};
    final enums = <String, EnumTypeDefinitionNode>{};
    final inputs = <String, InputObjectTypeDefinitionNode>{};
    final scalars = <String>{'String', 'ID', 'Int', 'Float', 'Boolean'};

    for (final def in doc.definitions) {
      if (def is ObjectTypeDefinitionNode) {
        objects[def.name.value] = def;
      } else if (def is InterfaceTypeDefinitionNode) {
        interfaces[def.name.value] = def;
      } else if (def is UnionTypeDefinitionNode) {
        unions[def.name.value] = def;
      } else if (def is EnumTypeDefinitionNode) {
        enums[def.name.value] = def;
      } else if (def is InputObjectTypeDefinitionNode) {
        inputs[def.name.value] = def;
      } else if (def is ScalarTypeDefinitionNode) {
        scalars.add(def.name.value);
      }
    }

    return Schema(
      queryType: query ?? 'Query',
      mutationType: mutation,
      subscriptionType: subscription,
      types: objects,
      interfaces: interfaces,
      unions: unions,
      enums: enums,
      inputs: inputs,
      scalars: scalars,
    );
  }
}

class TypeRef {
  TypeRef.named(this.name)
      : isNonNull = false,
        isList = false,
        ofType = null;
  TypeRef.list(this.ofType)
      : isList = true,
        isNonNull = false,
        name = null;
  TypeRef.nonNull(this.ofType)
      : isNonNull = true,
        isList = false,
        name = null;

  final bool isNonNull;
  final bool isList;
  final String? name;
  final TypeRef? ofType;

  TypeRef withNonNull(bool nonNull) {
    if (nonNull) {
      return TypeRef.nonNull(this);
    }
    return this;
  }

  static TypeRef fromNode(TypeNode node) {
    if (node is NamedTypeNode) {
      return TypeRef.named(node.name.value).withNonNull(node.isNonNull);
    }
    if (node is ListTypeNode) {
      final inner = fromNode(node.type);
      final listRef = TypeRef.list(inner);
      return listRef.withNonNull(node.isNonNull);
    }
    throw StateError('Unsupported type node');
  }
}
