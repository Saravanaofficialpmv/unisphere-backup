import 'package:flutter_web_plugins/url_strategy.dart';

/// Web implementation of URL strategy to remove '#' hash routing.
void configureAppUrlStrategy() {
  usePathUrlStrategy();
}
