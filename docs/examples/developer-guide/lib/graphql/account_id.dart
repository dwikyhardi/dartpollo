class AccountId {
  const AccountId(this.value);

  final String value;
}

AccountId fromGraphQLAccountIdToDartAccountId(String value) => AccountId(value);

String fromDartAccountIdToGraphQLAccountId(AccountId value) => value.value;

List<AccountId?>?
fromGraphQLListNullableAccountIdNullableToDartListNullableAccountIdNullable(
  List<Object?>? values,
) => values
    ?.map((value) => value == null ? null : AccountId(value as String))
    .toList();

List<String?>?
fromDartListNullableAccountIdNullableToGraphQLListNullableAccountIdNullable(
  List<AccountId?>? values,
) => values?.map((value) => value?.value).toList();
