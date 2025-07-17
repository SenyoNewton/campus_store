import 'package:campus_store/features/core/controllers/authentication_controller.dart';
import 'package:campus_store/features/personalization/controllers/wishlist_controller.dart';
import 'package:get/get.dart';
import 'package:campus_store/features/personalization/models/controllers/profile_controller.dart';
class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthenticationController());
    Get.lazyPut(() => ProfileController());
    Get.lazyPut(() => ListingController());
    Get.lazyPut(() => WishlistController());
    // Add more controllers here if needed
  }
}

class ListingController {
}
