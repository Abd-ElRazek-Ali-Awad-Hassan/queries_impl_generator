import 'package:analyzer/dart/constant/value.dart';
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
            ..._methodsAnnotatedWith<Query>(element.methods).map(
              (e) => '\n${_buildMethod(e)}',
            ),
            _buildExecuteActionIfHasInternetAccess(),
            _buildMapExceptionToFailureOn(),
            '}\n',
          ]))
        .toString();
  }

  String _buildMixinDeclaration(ClassElement element) =>
      'mixin _\$${element.name}Mixin {\n'
      '\n';

  String _buildMethod(MethodElement element) {
    final passedFunction = _getPassedFunctionToAnnotation(
      _getFirstAnnotationOn<Query>(element),
      'mapExceptionToFailure',
    );

    String? passedFunctionReference = switch (passedFunction) {
      (null) => null,
      (_) => switch (passedFunction.enclosingElement) {
          (ClassElement e) => '${e.displayName}.${passedFunction.displayName}',
          (_) => passedFunction.displayName,
        }
    };

    return '${element.returnType} _\$${element.name}(\n'
        ' ${element.returnType} Function() callback,\n'
        ') async =>\n'
        '_\$executeActionIfHasInternetAccess(\n'
        'action: () => ${passedFunctionReference ?? '_\$mapExceptionToFailureOn'}(callback: callback),\n'
        ');\n';
  }

  DartObject? _getFirstAnnotationOn<AnnotationType>(Element element) {
    return TypeChecker.fromRuntime(AnnotationType)
        .firstAnnotationOfExact(element);
  }

  ExecutableElement? _getPassedFunctionToAnnotation(
    DartObject? annotation,
    String functionVariableName,
  ) =>
      annotation?.getField(functionVariableName)?.toFunctionValue();

  Iterable<MethodElement> _methodsAnnotatedWith<AnnotationType>(
    Iterable<MethodElement> elements,
  ) {
    return elements.where(
      (element) => TypeChecker.fromRuntime(AnnotationType)
          .hasAnnotationOf(element, throwOnUnresolved: false),
    );
  }

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
