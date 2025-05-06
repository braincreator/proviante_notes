import 'package:easy_localization/easy_localization.dart'; // Import easy_localization

enum NoteSortOption {
  dateCreatedDescending,
  dateCreatedAscending,
  dateModifiedDescending,
  dateModifiedAscending,
  titleAscending,
  titleDescending,
}

extension NoteSortOptionX on NoteSortOption {
  String get displayName {
    // Use translation keys
    switch (this) {
      case NoteSortOption.dateCreatedDescending:
        return 'notesList.sortOptions.dateCreatedDesc'.tr();
      case NoteSortOption.dateCreatedAscending:
        return 'notesList.sortOptions.dateCreatedAsc'.tr();
      case NoteSortOption.dateModifiedDescending:
        return 'notesList.sortOptions.dateModifiedDesc'.tr();
      case NoteSortOption.dateModifiedAscending:
        return 'notesList.sortOptions.dateModifiedAsc'.tr();
      case NoteSortOption.titleAscending:
        return 'notesList.sortOptions.titleAsc'.tr();
      case NoteSortOption.titleDescending:
        return 'notesList.sortOptions.titleDesc'.tr();
    }
  }
}