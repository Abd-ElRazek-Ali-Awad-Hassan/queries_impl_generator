import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';

class QueriesImplGenerator extends GeneratorForAnnotation<GenerateForQueries> {
  const QueriesImplGenerator();

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (annotation.isNull) {
      throw InvalidGenerationSource(
        'The source annotation should be set!',
        element: element,
      );
    }
    if (element is! ClassElement) {
      throw InvalidGenerationSource(
        "'$GenerateForQueries()' only support classes",
        element: element,
      );
    }

    return (StringBuffer()
          ..writeAll([
            _buildMixinDeclaration(element),
            _buildConnectionCheckerInstanceDeclaration(),
            _buildConnectionCheckerInstanceSetter(),
            _buildExecuteActionIfHasInternetAccess(),
            _buildMapExceptionToFailureOn(),
            ..._methodsAnnotatedWith<Query>(element.methods).map(
              (e) => '\n${_buildMethod(e)}',
            ),
            '}\n',
          ]))
        .toString();
  }

  String _buildMixinDeclaration(ClassElement element) =>
      'mixin _\$${element.name}Mixin {\n'
      '\n';

  String _buildMethod(MethodElement element) =>
      '${element.returnType} _\$${element.name}(\n'
      ' ${element.returnType} Function() callback,\n'
      ') async =>\n'
      '_\$executeActionIfHasInternetAccess(\n'
      'action: () => _\$mapExceptionToFailureOn(callback: callback),\n'
      ');\n';

  Iterable<MethodElement> _methodsAnnotatedWith<AnnotationType>(
    Iterable<MethodElement> elements,
  ) =>
      elements.where(
        (element) => element.metadata
            .map((e) => e.element!.declaration!.displayName)
            .contains('$AnnotationType'),
      );

  String _buildConnectionCheckerInstanceDeclaration() =>
      'late final InternetConnectionChecker _checker;\n\n';

  String _buildConnectionCheckerInstanceSetter() =>
      'void _\$setInternetConnectionChecker(InternetConnectionChecker checker) =>'
      ' _checker = checker;'
      '\n\n';

  String _buildExecuteActionIfHasInternetAccess() =>
      'Future<Either<Failure, ReturnType>>\n'
      '_\$executeActionIfHasInternetAccess<ReturnType>({\n'
      'required Future<Either<Failure, ReturnType>> Function() action,\n'
      '}) async {\n'
      'if (!await _checker.hasInternetAccess) {\n'
      'return Left(NetworkFailure());\n'
      '}\n'
      'return action();\n'
      '}\n';

  String _buildMapExceptionToFailureOn() =>
      'Future<Either<Failure, ReturnType>> _\$mapExceptionToFailureOn<ReturnType>({\n'
      'required Future<Either<Failure, ReturnType>> Function() callback,\n'
      '}) async {\n'
      'try {\n'
      'return await callback();\n'
      '} on NetworkException {\n'
      'return Left(NetworkFailure());\n'
      '} on ServerException catch (exception) {\n'
      'return Left(ServerFailure(message: exception.message));\n'
      '} on CacheException catch (exception) {\n'
      'return Left(CacheFailure(message: exception.message));\n'
      '}\n'
      '}\n';
}
