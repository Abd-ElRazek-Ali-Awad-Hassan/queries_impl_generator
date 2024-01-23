/// Configuration for using `package:build`-compatible build systems.
///
/// See:
/// * [build_runner](https://pub.dev/packages/build_runner)
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline. See documentation for
/// details, and `build.yaml` for how these builders are configured by default.
library queries_impl_generator.builder;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/queries_impl_generator.dart';

Builder queriesImplBuilder(BuilderOptions options) =>
    SharedPartBuilder([QueriesImplGenerator()], 'queries_impl');
