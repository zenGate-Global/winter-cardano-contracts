use aiken/list
use aiken/transaction.{Output, Transaction}
use aiken/transaction/credential.{Address, PaymentCredential}
use aiken/transaction/value.{PolicyId}
use winter_protocol/datums.{VerificationKeyHash}

pub fn find_policy_id_outputs(
  outputs: List<Output>,
  policy_id: PolicyId,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) { list.has(value.policies(output.value), policy_id) },
  )
}

pub fn find_address_outputs(
  outputs: List<Output>,
  payment_credential: PaymentCredential,
) -> List<Output> {
  list.filter(
    outputs,
    fn(output) { output.address.payment_credential == payment_credential },
  )
}

pub fn must_be_signed_by_at_least_one(
  transaction: Transaction,
  vks: List<VerificationKeyHash>,
) -> Bool {
  has_any(transaction.extra_signatories, vks)
}

pub fn has_any(
  main_list: List<VerificationKeyHash>,
  elements: List<VerificationKeyHash>,
) -> Bool {
  list.any(elements, fn(element) { list.has(main_list, element) })
}
