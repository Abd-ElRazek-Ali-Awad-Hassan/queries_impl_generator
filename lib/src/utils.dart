import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

abstract class Utils {
  static String getFunctionReferenceAsStringFor(ExecutableElement element) {
    return (StringBuffer()
          ..writeAll([
            if (element.enclosingElement is ClassElement)
              '${element.enclosingElement.displayName}.',
            element.displayName,
          ]))
        .toString();
  }

  static DartObject? getFirstAnnotationOn<AnnotationType>(Element element) {
    return TypeChecker.fromRuntime(AnnotationType)
        .firstAnnotationOfExact(element);
  }

  static ExecutableElement? getPassedFunctionToAnnotation(
    DartObject? annotation,
    String functionVariableName,
  ) =>
      annotation?.getField(functionVariableName)?.toFunctionValue();

  static Iterable<MethodElement> methodsAnnotatedWith<AnnotationType>(
    Iterable<MethodElement> elements,
  ) {
    return elements.where(
      (element) => TypeChecker.fromRuntime(AnnotationType)
          .hasAnnotationOf(element, throwOnUnresolved: false),
    );
  }
}
