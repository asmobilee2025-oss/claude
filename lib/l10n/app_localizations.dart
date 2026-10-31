import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Souqna'**
  String get appName;

  /// No description provided for @otherLanguage.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get otherLanguage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @postAd.
  ///
  /// In en, this message translates to:
  /// **'Post ad'**
  String get postAd;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @featuredAds.
  ///
  /// In en, this message translates to:
  /// **'Featured ads'**
  String get featuredAds;

  /// No description provided for @latestAds.
  ///
  /// In en, this message translates to:
  /// **'Latest ads'**
  String get latestAds;

  /// No description provided for @noAdsYet.
  ///
  /// In en, this message translates to:
  /// **'No ads yet'**
  String get noAdsYet;

  /// No description provided for @beFirstToPost.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post an ad.'**
  String get beFirstToPost;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategories;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get searchHint;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @allCities.
  ///
  /// In en, this message translates to:
  /// **'All cities'**
  String get allCities;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get priceRange;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxPrice;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get conditionUsed;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceLow;

  /// No description provided for @sortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceHigh;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get showResults;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filters.'**
  String get tryDifferentFilters;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get tryAgainLater;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to post ads, chat and save favorites.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join to buy and sell in minutes.'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @acceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Use and Privacy Policy'**
  String get acceptTerms;

  /// No description provided for @mustAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms to continue'**
  String get mustAcceptTerms;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox.'**
  String get verificationSent;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a reset link.'**
  String get resetSubtitle;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a reset link has been sent.'**
  String get resetSent;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @sendAgain.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get sendAgain;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get invalidPrice;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordWeak.
  ///
  /// In en, this message translates to:
  /// **'Use letters and numbers'**
  String get passwordWeak;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get wrongCredentials;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailInUse;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled'**
  String get accountDisabled;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get tooManyRequests;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get networkError;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @iVerified.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified'**
  String get iVerified;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmail;

  /// No description provided for @notVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet'**
  String get notVerifiedYet;

  /// No description provided for @verifyEmailToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email to continue'**
  String get verifyEmailToContinue;

  /// No description provided for @accountBanned.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Contact support.'**
  String get accountBanned;

  /// No description provided for @notAllowed.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this page'**
  String get notAllowed;

  /// No description provided for @backHome.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backHome;

  /// No description provided for @adNotFound.
  ///
  /// In en, this message translates to:
  /// **'This ad is no longer available'**
  String get adNotFound;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiable;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @chatWithSeller.
  ///
  /// In en, this message translates to:
  /// **'Chat with seller'**
  String get chatWithSeller;

  /// No description provided for @showPhone.
  ///
  /// In en, this message translates to:
  /// **'Show phone'**
  String get showPhone;

  /// No description provided for @whatsappGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, I\'m interested in your ad'**
  String get whatsappGreeting;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay safe'**
  String get safetyTitle;

  /// No description provided for @safetyTips.
  ///
  /// In en, this message translates to:
  /// **'Meet in public places, inspect the item before paying, and never send money in advance.'**
  String get safetyTips;

  /// No description provided for @reportAd.
  ///
  /// In en, this message translates to:
  /// **'Report ad'**
  String get reportAd;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks. Our team will review it.'**
  String get reportSent;

  /// No description provided for @reportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'More details (optional)'**
  String get reportDetailsHint;

  /// No description provided for @moreFromSeller.
  ///
  /// In en, this message translates to:
  /// **'More from this seller'**
  String get moreFromSeller;

  /// No description provided for @manageYourAd.
  ///
  /// In en, this message translates to:
  /// **'Manage your ad'**
  String get manageYourAd;

  /// No description provided for @markAsSold.
  ///
  /// In en, this message translates to:
  /// **'Mark as sold'**
  String get markAsSold;

  /// No description provided for @markAsSoldConfirm.
  ///
  /// In en, this message translates to:
  /// **'The ad will be hidden from search.'**
  String get markAsSoldConfirm;

  /// No description provided for @deleteAd.
  ///
  /// In en, this message translates to:
  /// **'Delete ad'**
  String get deleteAd;

  /// No description provided for @deleteAdConfirm.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteAdConfirm;

  /// No description provided for @adDeleted.
  ///
  /// In en, this message translates to:
  /// **'Ad deleted'**
  String get adDeleted;

  /// No description provided for @moderateInAdmin.
  ///
  /// In en, this message translates to:
  /// **'Moderate in admin'**
  String get moderateInAdmin;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or duplicate'**
  String get reasonSpam;

  /// No description provided for @reasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get reasonFraud;

  /// No description provided for @reasonProhibited.
  ///
  /// In en, this message translates to:
  /// **'Prohibited item'**
  String get reasonProhibited;

  /// No description provided for @reasonWrongCategory.
  ///
  /// In en, this message translates to:
  /// **'Wrong category'**
  String get reasonWrongCategory;

  /// No description provided for @reasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get reasonOffensive;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get statusSold;

  /// No description provided for @pendingExplain.
  ///
  /// In en, this message translates to:
  /// **'Your ad is being reviewed and will be visible once approved.'**
  String get pendingExplain;

  /// No description provided for @rejectedExplain.
  ///
  /// In en, this message translates to:
  /// **'This ad was rejected. Edit it and resubmit.'**
  String get rejectedExplain;

  /// No description provided for @soldExplain.
  ///
  /// In en, this message translates to:
  /// **'This item has been sold.'**
  String get soldExplain;

  /// No description provided for @editAd.
  ///
  /// In en, this message translates to:
  /// **'Edit ad'**
  String get editAd;

  /// No description provided for @adTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get adTitle;

  /// No description provided for @adTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. iPhone 15 Pro 256GB, like new'**
  String get adTitleHint;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Condition, specs, reason for selling…'**
  String get descriptionHint;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get contactPhone;

  /// No description provided for @showPhoneOnAd.
  ///
  /// In en, this message translates to:
  /// **'Show my phone on the ad'**
  String get showPhoneOnAd;

  /// No description provided for @showPhoneOnAdHint.
  ///
  /// In en, this message translates to:
  /// **'Buyers can call or WhatsApp you'**
  String get showPhoneOnAdHint;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @photosHint.
  ///
  /// In en, this message translates to:
  /// **'The first photo is the cover. Clear photos sell faster.'**
  String get photosHint;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addPhotos;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @makeCover.
  ///
  /// In en, this message translates to:
  /// **'Make cover'**
  String get makeCover;

  /// No description provided for @addAtLeastOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add at least one photo'**
  String get addAtLeastOnePhoto;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is larger than 5 MB'**
  String get imageTooLarge;

  /// No description provided for @publishAd.
  ///
  /// In en, this message translates to:
  /// **'Publish ad'**
  String get publishAd;

  /// No description provided for @adPublished.
  ///
  /// In en, this message translates to:
  /// **'Your ad is live'**
  String get adPublished;

  /// No description provided for @adSubmittedForReview.
  ///
  /// In en, this message translates to:
  /// **'Submitted. Your ad will appear after review.'**
  String get adSubmittedForReview;

  /// No description provided for @editReReview.
  ///
  /// In en, this message translates to:
  /// **'Saving changes sends the ad back for review.'**
  String get editReReview;

  /// No description provided for @loginToChat.
  ///
  /// In en, this message translates to:
  /// **'Log in to see your chats'**
  String get loginToChat;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noChats;

  /// No description provided for @noChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Message a seller from any ad to start.'**
  String get noChatsHint;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello 👋'**
  String get sayHello;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeMessage;

  /// No description provided for @messageNotSent.
  ///
  /// In en, this message translates to:
  /// **'Message not sent'**
  String get messageNotSent;

  /// No description provided for @myDashboard.
  ///
  /// In en, this message translates to:
  /// **'My dashboard'**
  String get myDashboard;

  /// No description provided for @guestTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re browsing as a guest'**
  String get guestTitle;

  /// No description provided for @guestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to post ads, chat with sellers and save favorites.'**
  String get guestSubtitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get notVerified;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @activeAds.
  ///
  /// In en, this message translates to:
  /// **'Active ads'**
  String get activeAds;

  /// No description provided for @pendingAds.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingAds;

  /// No description provided for @totalViews.
  ///
  /// In en, this message translates to:
  /// **'Total views'**
  String get totalViews;

  /// No description provided for @myAds.
  ///
  /// In en, this message translates to:
  /// **'My ads'**
  String get myAds;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @noAdsHere.
  ///
  /// In en, this message translates to:
  /// **'No ads here'**
  String get noAdsHere;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get noFavorites;

  /// No description provided for @noFavoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any ad to save it.'**
  String get noFavoritesHint;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get bio;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileSaved;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp support'**
  String get contactSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get emailSupport;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'Buy and sell anything near you.'**
  String get aboutText;

  /// No description provided for @sellerAds.
  ///
  /// In en, this message translates to:
  /// **'Seller\'s ads'**
  String get sellerAds;

  /// No description provided for @memberSinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSinceLabel;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminDashboard;

  /// No description provided for @backToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to app'**
  String get backToApp;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @overviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live numbers across the marketplace.'**
  String get overviewSubtitle;

  /// No description provided for @adsModeration.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get adsModeration;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appSettings;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get totalUsers;

  /// No description provided for @totalAds.
  ///
  /// In en, this message translates to:
  /// **'Total ads'**
  String get totalAds;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get pendingReview;

  /// No description provided for @openReports.
  ///
  /// In en, this message translates to:
  /// **'Open reports'**
  String get openReports;

  /// No description provided for @bannedUsers.
  ///
  /// In en, this message translates to:
  /// **'Banned users'**
  String get bannedUsers;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get thisWeek;

  /// No description provided for @adsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Ads by status'**
  String get adsByStatus;

  /// No description provided for @searchAdsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Search by title, seller or ID'**
  String get searchAdsAdmin;

  /// No description provided for @nothingToReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingToReview;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @rejectAd.
  ///
  /// In en, this message translates to:
  /// **'Reject ad'**
  String get rejectAd;

  /// No description provided for @rejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason shown to the seller'**
  String get rejectReasonHint;

  /// No description provided for @adApproved.
  ///
  /// In en, this message translates to:
  /// **'Ad approved'**
  String get adApproved;

  /// No description provided for @adRejected.
  ///
  /// In en, this message translates to:
  /// **'Ad rejected'**
  String get adRejected;

  /// No description provided for @feature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get feature;

  /// No description provided for @unfeature.
  ///
  /// In en, this message translates to:
  /// **'Unfeature'**
  String get unfeature;

  /// No description provided for @markedFeatured.
  ///
  /// In en, this message translates to:
  /// **'Ad is now featured'**
  String get markedFeatured;

  /// No description provided for @unfeatured.
  ///
  /// In en, this message translates to:
  /// **'Removed from featured'**
  String get unfeatured;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users by name or UID'**
  String get searchUsers;

  /// No description provided for @banned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get banned;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @banUser.
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get banUser;

  /// No description provided for @unbanUser.
  ///
  /// In en, this message translates to:
  /// **'Unban user'**
  String get unbanUser;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get removeAdmin;

  /// No description provided for @viewAds.
  ///
  /// In en, this message translates to:
  /// **'View ads'**
  String get viewAds;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Existing ads keep their category ID.'**
  String get deleteCategoryConfirm;

  /// No description provided for @seedCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Load a ready-made set of bilingual categories to get started.'**
  String get seedCategoriesHint;

  /// No description provided for @loadDefaultCategories.
  ///
  /// In en, this message translates to:
  /// **'Load default categories'**
  String get loadDefaultCategories;

  /// No description provided for @categoryId.
  ///
  /// In en, this message translates to:
  /// **'ID (slug)'**
  String get categoryId;

  /// No description provided for @invalidSlug.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, numbers and dashes only'**
  String get invalidSlug;

  /// No description provided for @nameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get nameEnglish;

  /// No description provided for @nameArabic.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get nameArabic;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @reportOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get reportOpen;

  /// No description provided for @reportResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get reportResolved;

  /// No description provided for @reportDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get reportDismissed;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No reports'**
  String get noReports;

  /// No description provided for @viewAd.
  ///
  /// In en, this message translates to:
  /// **'View ad'**
  String get viewAd;

  /// No description provided for @takeDownAd.
  ///
  /// In en, this message translates to:
  /// **'Take down ad'**
  String get takeDownAd;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get markResolved;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @autoApprove.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve new ads'**
  String get autoApprove;

  /// No description provided for @autoApproveHint.
  ///
  /// In en, this message translates to:
  /// **'When off, every new or edited ad waits for admin review.'**
  String get autoApproveHint;

  /// No description provided for @supportWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Support WhatsApp number'**
  String get supportWhatsapp;

  /// No description provided for @supportEmail.
  ///
  /// In en, this message translates to:
  /// **'Support email'**
  String get supportEmail;

  /// No description provided for @announcementEnglish.
  ///
  /// In en, this message translates to:
  /// **'Home announcement (English)'**
  String get announcementEnglish;

  /// No description provided for @announcementArabic.
  ///
  /// In en, this message translates to:
  /// **'Home announcement (Arabic)'**
  String get announcementArabic;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @tooShort.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters'**
  String tooShort(int min);

  /// No description provided for @tooLong.
  ///
  /// In en, this message translates to:
  /// **'At most {max} characters'**
  String tooLong(int max);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Yesterday} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @viewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No views} =1{1 view} other{{count} views}}'**
  String viewsCount(int count);

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @verifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'We sent a link to {email}. Verify your email to post ads and chat.'**
  String verifyEmailBody(String email);

  /// No description provided for @maxImagesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} photos'**
  String maxImagesReached(int count);

  /// No description provided for @maxImagesPerAd.
  ///
  /// In en, this message translates to:
  /// **'Max photos per ad: {count}'**
  String maxImagesPerAd(int count);

  /// No description provided for @banConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name} won\'t be able to post, edit or chat.'**
  String banConfirm(String name);

  /// No description provided for @makeAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'{name} will get full access to the admin dashboard.'**
  String makeAdminConfirm(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
