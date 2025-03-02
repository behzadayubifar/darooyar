// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prescription_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiClientHash() => r'830b3339c24d952121db45e5d7278545d0d2fbfd';

/// See also [apiClient].
@ProviderFor(apiClient)
final apiClientProvider = AutoDisposeProvider<ApiClient>.internal(
  apiClient,
  name: r'apiClientProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiClientRef = AutoDisposeProviderRef<ApiClient>;
String _$databaseServiceHash() => r'766f41a8fb8947216fae68bbc31fa62d037f6899';

/// See also [databaseService].
@ProviderFor(databaseService)
final databaseServiceProvider = AutoDisposeProvider<DatabaseService>.internal(
  databaseService,
  name: r'databaseServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DatabaseServiceRef = AutoDisposeProviderRef<DatabaseService>;
String _$messageMigrationServiceHash() =>
    r'eba5fea57d5de2c16b2005a39136ede0a78db565';

/// See also [messageMigrationService].
@ProviderFor(messageMigrationService)
final messageMigrationServiceProvider =
    AutoDisposeProvider<MessageMigrationService>.internal(
  messageMigrationService,
  name: r'messageMigrationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageMigrationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MessageMigrationServiceRef
    = AutoDisposeProviderRef<MessageMigrationService>;
String _$prescriptionRepositoryHash() =>
    r'a638132c7f0c33e02bfddcc648709e1ae4cc319e';

/// See also [prescriptionRepository].
@ProviderFor(prescriptionRepository)
final prescriptionRepositoryProvider =
    AutoDisposeProvider<PrescriptionRepository>.internal(
  prescriptionRepository,
  name: r'prescriptionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$prescriptionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PrescriptionRepositoryRef
    = AutoDisposeProviderRef<PrescriptionRepository>;
String _$prescriptionsHash() => r'8bd3ec6bc9015e9775988de9b35283675d4fe3b9';

/// See also [prescriptions].
@ProviderFor(prescriptions)
final prescriptionsProvider =
    AutoDisposeFutureProvider<List<PrescriptionEntity>>.internal(
  prescriptions,
  name: r'prescriptionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$prescriptionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PrescriptionsRef
    = AutoDisposeFutureProviderRef<List<PrescriptionEntity>>;
String _$selectedPrescriptionHash() =>
    r'59eb918022b253ca61c5298b3021027271ec1c7f';

/// See also [selectedPrescription].
@ProviderFor(selectedPrescription)
final selectedPrescriptionProvider =
    AutoDisposeFutureProvider<PrescriptionEntity?>.internal(
  selectedPrescription,
  name: r'selectedPrescriptionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPrescriptionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SelectedPrescriptionRef
    = AutoDisposeFutureProviderRef<PrescriptionEntity?>;
String _$prescriptionMessagesHash() =>
    r'6900c5bb0f462d6681aab59ca5315492b1a32ad5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [prescriptionMessages].
@ProviderFor(prescriptionMessages)
const prescriptionMessagesProvider = PrescriptionMessagesFamily();

/// See also [prescriptionMessages].
class PrescriptionMessagesFamily
    extends Family<AsyncValue<List<PrescriptionMessageEntity>>> {
  /// See also [prescriptionMessages].
  const PrescriptionMessagesFamily();

  /// See also [prescriptionMessages].
  PrescriptionMessagesProvider call(
    String prescriptionId,
  ) {
    return PrescriptionMessagesProvider(
      prescriptionId,
    );
  }

  @override
  PrescriptionMessagesProvider getProviderOverride(
    covariant PrescriptionMessagesProvider provider,
  ) {
    return call(
      provider.prescriptionId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'prescriptionMessagesProvider';
}

/// See also [prescriptionMessages].
class PrescriptionMessagesProvider
    extends AutoDisposeFutureProvider<List<PrescriptionMessageEntity>> {
  /// See also [prescriptionMessages].
  PrescriptionMessagesProvider(
    String prescriptionId,
  ) : this._internal(
          (ref) => prescriptionMessages(
            ref as PrescriptionMessagesRef,
            prescriptionId,
          ),
          from: prescriptionMessagesProvider,
          name: r'prescriptionMessagesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$prescriptionMessagesHash,
          dependencies: PrescriptionMessagesFamily._dependencies,
          allTransitiveDependencies:
              PrescriptionMessagesFamily._allTransitiveDependencies,
          prescriptionId: prescriptionId,
        );

  PrescriptionMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.prescriptionId,
  }) : super.internal();

  final String prescriptionId;

  @override
  Override overrideWith(
    FutureOr<List<PrescriptionMessageEntity>> Function(
            PrescriptionMessagesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PrescriptionMessagesProvider._internal(
        (ref) => create(ref as PrescriptionMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        prescriptionId: prescriptionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PrescriptionMessageEntity>>
      createElement() {
    return _PrescriptionMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PrescriptionMessagesProvider &&
        other.prescriptionId == prescriptionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, prescriptionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PrescriptionMessagesRef
    on AutoDisposeFutureProviderRef<List<PrescriptionMessageEntity>> {
  /// The parameter `prescriptionId` of this provider.
  String get prescriptionId;
}

class _PrescriptionMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<PrescriptionMessageEntity>>
    with PrescriptionMessagesRef {
  _PrescriptionMessagesProviderElement(super.provider);

  @override
  String get prescriptionId =>
      (origin as PrescriptionMessagesProvider).prescriptionId;
}

String _$createPrescriptionFromTextHash() =>
    r'ea10fb1ad0b8edc17730b24411174cbadd9cadac';

/// See also [createPrescriptionFromText].
@ProviderFor(createPrescriptionFromText)
const createPrescriptionFromTextProvider = CreatePrescriptionFromTextFamily();

/// See also [createPrescriptionFromText].
class CreatePrescriptionFromTextFamily
    extends Family<AsyncValue<PrescriptionEntity>> {
  /// See also [createPrescriptionFromText].
  const CreatePrescriptionFromTextFamily();

  /// See also [createPrescriptionFromText].
  CreatePrescriptionFromTextProvider call(
    ({String text, String title}) params,
  ) {
    return CreatePrescriptionFromTextProvider(
      params,
    );
  }

  @override
  CreatePrescriptionFromTextProvider getProviderOverride(
    covariant CreatePrescriptionFromTextProvider provider,
  ) {
    return call(
      provider.params,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createPrescriptionFromTextProvider';
}

/// See also [createPrescriptionFromText].
class CreatePrescriptionFromTextProvider
    extends AutoDisposeFutureProvider<PrescriptionEntity> {
  /// See also [createPrescriptionFromText].
  CreatePrescriptionFromTextProvider(
    ({String text, String title}) params,
  ) : this._internal(
          (ref) => createPrescriptionFromText(
            ref as CreatePrescriptionFromTextRef,
            params,
          ),
          from: createPrescriptionFromTextProvider,
          name: r'createPrescriptionFromTextProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$createPrescriptionFromTextHash,
          dependencies: CreatePrescriptionFromTextFamily._dependencies,
          allTransitiveDependencies:
              CreatePrescriptionFromTextFamily._allTransitiveDependencies,
          params: params,
        );

  CreatePrescriptionFromTextProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String text, String title}) params;

  @override
  Override overrideWith(
    FutureOr<PrescriptionEntity> Function(
            CreatePrescriptionFromTextRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreatePrescriptionFromTextProvider._internal(
        (ref) => create(ref as CreatePrescriptionFromTextRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PrescriptionEntity> createElement() {
    return _CreatePrescriptionFromTextProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreatePrescriptionFromTextProvider &&
        other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CreatePrescriptionFromTextRef
    on AutoDisposeFutureProviderRef<PrescriptionEntity> {
  /// The parameter `params` of this provider.
  ({String text, String title}) get params;
}

class _CreatePrescriptionFromTextProviderElement
    extends AutoDisposeFutureProviderElement<PrescriptionEntity>
    with CreatePrescriptionFromTextRef {
  _CreatePrescriptionFromTextProviderElement(super.provider);

  @override
  ({String text, String title}) get params =>
      (origin as CreatePrescriptionFromTextProvider).params;
}

String _$createPrescriptionFromImageHash() =>
    r'0059419eccb65bcba979e7cfd493eeea1c0345b9';

/// See also [createPrescriptionFromImage].
@ProviderFor(createPrescriptionFromImage)
const createPrescriptionFromImageProvider = CreatePrescriptionFromImageFamily();

/// See also [createPrescriptionFromImage].
class CreatePrescriptionFromImageFamily
    extends Family<AsyncValue<PrescriptionEntity>> {
  /// See also [createPrescriptionFromImage].
  const CreatePrescriptionFromImageFamily();

  /// See also [createPrescriptionFromImage].
  CreatePrescriptionFromImageProvider call(
    ({File image, String title}) params,
  ) {
    return CreatePrescriptionFromImageProvider(
      params,
    );
  }

  @override
  CreatePrescriptionFromImageProvider getProviderOverride(
    covariant CreatePrescriptionFromImageProvider provider,
  ) {
    return call(
      provider.params,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'createPrescriptionFromImageProvider';
}

/// See also [createPrescriptionFromImage].
class CreatePrescriptionFromImageProvider
    extends AutoDisposeFutureProvider<PrescriptionEntity> {
  /// See also [createPrescriptionFromImage].
  CreatePrescriptionFromImageProvider(
    ({File image, String title}) params,
  ) : this._internal(
          (ref) => createPrescriptionFromImage(
            ref as CreatePrescriptionFromImageRef,
            params,
          ),
          from: createPrescriptionFromImageProvider,
          name: r'createPrescriptionFromImageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$createPrescriptionFromImageHash,
          dependencies: CreatePrescriptionFromImageFamily._dependencies,
          allTransitiveDependencies:
              CreatePrescriptionFromImageFamily._allTransitiveDependencies,
          params: params,
        );

  CreatePrescriptionFromImageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({File image, String title}) params;

  @override
  Override overrideWith(
    FutureOr<PrescriptionEntity> Function(
            CreatePrescriptionFromImageRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CreatePrescriptionFromImageProvider._internal(
        (ref) => create(ref as CreatePrescriptionFromImageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PrescriptionEntity> createElement() {
    return _CreatePrescriptionFromImageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CreatePrescriptionFromImageProvider &&
        other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CreatePrescriptionFromImageRef
    on AutoDisposeFutureProviderRef<PrescriptionEntity> {
  /// The parameter `params` of this provider.
  ({File image, String title}) get params;
}

class _CreatePrescriptionFromImageProviderElement
    extends AutoDisposeFutureProviderElement<PrescriptionEntity>
    with CreatePrescriptionFromImageRef {
  _CreatePrescriptionFromImageProviderElement(super.provider);

  @override
  ({File image, String title}) get params =>
      (origin as CreatePrescriptionFromImageProvider).params;
}

String _$sendFollowUpMessageHash() =>
    r'e9683e3239a2099d7a43ee51ad0a443092dd884b';

/// See also [sendFollowUpMessage].
@ProviderFor(sendFollowUpMessage)
const sendFollowUpMessageProvider = SendFollowUpMessageFamily();

/// See also [sendFollowUpMessage].
class SendFollowUpMessageFamily
    extends Family<AsyncValue<PrescriptionMessageEntity>> {
  /// See also [sendFollowUpMessage].
  const SendFollowUpMessageFamily();

  /// See also [sendFollowUpMessage].
  SendFollowUpMessageProvider call(
    ({String message, String prescriptionId}) params,
  ) {
    return SendFollowUpMessageProvider(
      params,
    );
  }

  @override
  SendFollowUpMessageProvider getProviderOverride(
    covariant SendFollowUpMessageProvider provider,
  ) {
    return call(
      provider.params,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sendFollowUpMessageProvider';
}

/// See also [sendFollowUpMessage].
class SendFollowUpMessageProvider
    extends AutoDisposeFutureProvider<PrescriptionMessageEntity> {
  /// See also [sendFollowUpMessage].
  SendFollowUpMessageProvider(
    ({String message, String prescriptionId}) params,
  ) : this._internal(
          (ref) => sendFollowUpMessage(
            ref as SendFollowUpMessageRef,
            params,
          ),
          from: sendFollowUpMessageProvider,
          name: r'sendFollowUpMessageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$sendFollowUpMessageHash,
          dependencies: SendFollowUpMessageFamily._dependencies,
          allTransitiveDependencies:
              SendFollowUpMessageFamily._allTransitiveDependencies,
          params: params,
        );

  SendFollowUpMessageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String message, String prescriptionId}) params;

  @override
  Override overrideWith(
    FutureOr<PrescriptionMessageEntity> Function(
            SendFollowUpMessageRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SendFollowUpMessageProvider._internal(
        (ref) => create(ref as SendFollowUpMessageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PrescriptionMessageEntity> createElement() {
    return _SendFollowUpMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SendFollowUpMessageProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SendFollowUpMessageRef
    on AutoDisposeFutureProviderRef<PrescriptionMessageEntity> {
  /// The parameter `params` of this provider.
  ({String message, String prescriptionId}) get params;
}

class _SendFollowUpMessageProviderElement
    extends AutoDisposeFutureProviderElement<PrescriptionMessageEntity>
    with SendFollowUpMessageRef {
  _SendFollowUpMessageProviderElement(super.provider);

  @override
  ({String message, String prescriptionId}) get params =>
      (origin as SendFollowUpMessageProvider).params;
}

String _$deletePrescriptionHash() =>
    r'82968f3e286773eedd5d0118dd276a994a848c9b';

/// See also [deletePrescription].
@ProviderFor(deletePrescription)
const deletePrescriptionProvider = DeletePrescriptionFamily();

/// See also [deletePrescription].
class DeletePrescriptionFamily extends Family<AsyncValue<void>> {
  /// See also [deletePrescription].
  const DeletePrescriptionFamily();

  /// See also [deletePrescription].
  DeletePrescriptionProvider call(
    String prescriptionId,
  ) {
    return DeletePrescriptionProvider(
      prescriptionId,
    );
  }

  @override
  DeletePrescriptionProvider getProviderOverride(
    covariant DeletePrescriptionProvider provider,
  ) {
    return call(
      provider.prescriptionId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deletePrescriptionProvider';
}

/// See also [deletePrescription].
class DeletePrescriptionProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deletePrescription].
  DeletePrescriptionProvider(
    String prescriptionId,
  ) : this._internal(
          (ref) => deletePrescription(
            ref as DeletePrescriptionRef,
            prescriptionId,
          ),
          from: deletePrescriptionProvider,
          name: r'deletePrescriptionProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deletePrescriptionHash,
          dependencies: DeletePrescriptionFamily._dependencies,
          allTransitiveDependencies:
              DeletePrescriptionFamily._allTransitiveDependencies,
          prescriptionId: prescriptionId,
        );

  DeletePrescriptionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.prescriptionId,
  }) : super.internal();

  final String prescriptionId;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeletePrescriptionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeletePrescriptionProvider._internal(
        (ref) => create(ref as DeletePrescriptionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        prescriptionId: prescriptionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeletePrescriptionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeletePrescriptionProvider &&
        other.prescriptionId == prescriptionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, prescriptionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DeletePrescriptionRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `prescriptionId` of this provider.
  String get prescriptionId;
}

class _DeletePrescriptionProviderElement
    extends AutoDisposeFutureProviderElement<void> with DeletePrescriptionRef {
  _DeletePrescriptionProviderElement(super.provider);

  @override
  String get prescriptionId =>
      (origin as DeletePrescriptionProvider).prescriptionId;
}

String _$deleteMessageHash() => r'c7c55ec16496844c43a6e3cfd13244deb5ea6503';

/// See also [deleteMessage].
@ProviderFor(deleteMessage)
const deleteMessageProvider = DeleteMessageFamily();

/// See also [deleteMessage].
class DeleteMessageFamily extends Family<AsyncValue<void>> {
  /// See also [deleteMessage].
  const DeleteMessageFamily();

  /// See also [deleteMessage].
  DeleteMessageProvider call(
    ({String messageId, String prescriptionId}) params,
  ) {
    return DeleteMessageProvider(
      params,
    );
  }

  @override
  DeleteMessageProvider getProviderOverride(
    covariant DeleteMessageProvider provider,
  ) {
    return call(
      provider.params,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deleteMessageProvider';
}

/// See also [deleteMessage].
class DeleteMessageProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deleteMessage].
  DeleteMessageProvider(
    ({String messageId, String prescriptionId}) params,
  ) : this._internal(
          (ref) => deleteMessage(
            ref as DeleteMessageRef,
            params,
          ),
          from: deleteMessageProvider,
          name: r'deleteMessageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$deleteMessageHash,
          dependencies: DeleteMessageFamily._dependencies,
          allTransitiveDependencies:
              DeleteMessageFamily._allTransitiveDependencies,
          params: params,
        );

  DeleteMessageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String messageId, String prescriptionId}) params;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeleteMessageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteMessageProvider._internal(
        (ref) => create(ref as DeleteMessageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeleteMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteMessageProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin DeleteMessageRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `params` of this provider.
  ({String messageId, String prescriptionId}) get params;
}

class _DeleteMessageProviderElement
    extends AutoDisposeFutureProviderElement<void> with DeleteMessageRef {
  _DeleteMessageProviderElement(super.provider);

  @override
  ({String messageId, String prescriptionId}) get params =>
      (origin as DeleteMessageProvider).params;
}

String _$updateMessageHash() => r'17c5adaafb2bc5102f7e3e1f314ea716e72abd0e';

/// See also [updateMessage].
@ProviderFor(updateMessage)
const updateMessageProvider = UpdateMessageFamily();

/// See also [updateMessage].
class UpdateMessageFamily extends Family<AsyncValue<void>> {
  /// See also [updateMessage].
  const UpdateMessageFamily();

  /// See also [updateMessage].
  UpdateMessageProvider call(
    PrescriptionMessageEntity message,
  ) {
    return UpdateMessageProvider(
      message,
    );
  }

  @override
  UpdateMessageProvider getProviderOverride(
    covariant UpdateMessageProvider provider,
  ) {
    return call(
      provider.message,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'updateMessageProvider';
}

/// See also [updateMessage].
class UpdateMessageProvider extends AutoDisposeFutureProvider<void> {
  /// See also [updateMessage].
  UpdateMessageProvider(
    PrescriptionMessageEntity message,
  ) : this._internal(
          (ref) => updateMessage(
            ref as UpdateMessageRef,
            message,
          ),
          from: updateMessageProvider,
          name: r'updateMessageProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updateMessageHash,
          dependencies: UpdateMessageFamily._dependencies,
          allTransitiveDependencies:
              UpdateMessageFamily._allTransitiveDependencies,
          message: message,
        );

  UpdateMessageProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.message,
  }) : super.internal();

  final PrescriptionMessageEntity message;

  @override
  Override overrideWith(
    FutureOr<void> Function(UpdateMessageRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdateMessageProvider._internal(
        (ref) => create(ref as UpdateMessageRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        message: message,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _UpdateMessageProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateMessageProvider && other.message == message;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, message.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UpdateMessageRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `message` of this provider.
  PrescriptionMessageEntity get message;
}

class _UpdateMessageProviderElement
    extends AutoDisposeFutureProviderElement<void> with UpdateMessageRef {
  _UpdateMessageProviderElement(super.provider);

  @override
  PrescriptionMessageEntity get message =>
      (origin as UpdateMessageProvider).message;
}

String _$selectedPrescriptionIdHash() =>
    r'f6bed3f997251ec543e4c5ac4e6bb494e262a866';

/// See also [SelectedPrescriptionId].
@ProviderFor(SelectedPrescriptionId)
final selectedPrescriptionIdProvider =
    AutoDisposeNotifierProvider<SelectedPrescriptionId, String?>.internal(
  SelectedPrescriptionId.new,
  name: r'selectedPrescriptionIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPrescriptionIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedPrescriptionId = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
