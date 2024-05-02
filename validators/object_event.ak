use aiken/dict
use aiken/list
use aiken/transaction.{
  Input, Output, OutputReference, ScriptContext, Spend, Transaction,
}
use aiken/transaction/credential.{Address, PaymentCredential, ScriptCredential}
use aiken/transaction/value
use winter_protocol/datums.{ObjectDatum, valid_datum_recreation}
use winter_protocol/utils.{
  find_address_outputs, find_policy_id_outputs, must_be_signed_by_at_least_one,
}

type Event {
  RecreateEvent
  SpendEvent
}

validator(payment_credential: PaymentCredential, fee_value_lovelace: Int) {
  fn object_event(
    datum: ObjectDatum,
    redeemer: Event,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(my_output_reference) ->
        when redeemer is {
          RecreateEvent -> and {
              valid_recreate_event(my_output_reference, ctx, datum)?,
              must_be_signed_by_at_least_one(ctx.transaction, datum.signers)?,
              valid_winter_fee(ctx, payment_credential, fee_value_lovelace)?,
            }
          SpendEvent -> and {
              valid_burn(ctx, my_output_reference)?,
              valid_winter_fee(ctx, payment_credential, fee_value_lovelace)?,
              must_be_signed_by_at_least_one(ctx.transaction, datum.signers)?,
            }
        }
      _ -> False
    }
  }
}

fn valid_recreate_event(
  my_output_reference: OutputReference,
  ctx: ScriptContext,
  datum: ObjectDatum,
) -> Bool {
  //Find the input guarded by this validator
  expect Some(self) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let self_tokens = value.without_lovelace(self.output.value)
  expect Some(self_singleton_policy_id) = list.head(value.policies(self_tokens))

  expect ScriptCredential(self_script) = self.output.address.payment_credential
  let self_script_outputs =
    ctx.transaction.outputs
      |> transaction.find_script_outputs(self_script)

  expect Some(recreated_event_box_out) =
    list.head(
      find_policy_id_outputs(self_script_outputs, self_singleton_policy_id),
    )

  // original was this `value.lovelace_of(self.output.value)`, changed due to offchain limitations
  let valid_ada_transfer =
    value.lovelace_of(recreated_event_box_out.value) >= 1_000_000

  let valid_singleton_transfer =
    list.length(
      value.policies(value.without_lovelace(recreated_event_box_out.value)),
    ) == 1

  and {
    valid_ada_transfer?,
    valid_singleton_transfer?,
    valid_datum_recreation(self, datum, recreated_event_box_out)?,
  }
}

fn valid_winter_fee(
  ctx: ScriptContext,
  payment_credential: PaymentCredential,
  fee_value_lovelace: Int,
) -> Bool {
  let valid_outputs =
    find_address_outputs(ctx.transaction.outputs, payment_credential)
  expect Some(winter_fee_output) = list.head(valid_outputs)
  and {
    (list.length(valid_outputs) == 1)?,
    (list.length(
      value.policies(value.without_lovelace(winter_fee_output.value)),
    ) == 0)?,
    (value.lovelace_of(winter_fee_output.value) >= fee_value_lovelace)?,
  }
}

fn valid_burn(ctx: ScriptContext, my_output_reference: OutputReference) -> Bool {
  let ScriptContext { transaction, .. } = ctx
  let Transaction { mint, .. } = transaction

  expect Some(self) =
    ctx.transaction.inputs
      |> transaction.find_input(my_output_reference)

  let self_tokens = value.without_lovelace(self.output.value)
  expect Some(self_singleton_policy_id) = list.head(value.policies(self_tokens))

  expect [(_asset_name, amount)] =
    mint
      |> value.from_minted_value
      |> value.tokens(self_singleton_policy_id)
      |> dict.to_list()

  list.length(value.policies(self_tokens)) == 1 && amount == -1
}
