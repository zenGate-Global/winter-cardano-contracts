use aiken/hash.{Blake2b_224, Blake2b_256, Hash}
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, TransactionId,
}
use aiken/transaction/credential.{VerificationKey}

pub type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type ObjectDatum {
  protocol_version: Int,
  data_reference: ByteArray,
  event_creation_info: Hash<Blake2b_256, Transaction>,
  signers: List<VerificationKeyHash>,
}

pub fn valid_datum_recreation(
  self_input: Input,
  datum: ObjectDatum,
  output: Output,
) -> Bool {
  expect InlineDatum(output_datum) = output.datum
  let casted_output_datum = to_object_datum(output_datum)
  and {
    datum.protocol_version == casted_output_datum.protocol_version,
    datum.data_reference == casted_output_datum.data_reference,
    valid_event_creation_info(self_input, datum, casted_output_datum),
    datum.signers == casted_output_datum.signers,
  }
}

fn valid_event_creation_info(
  self_input: Input,
  datum: ObjectDatum,
  recreated_datum: ObjectDatum,
) -> Bool {
  if datum.event_creation_info == "" {
    recreated_datum.event_creation_info == self_input.output_reference.transaction_id.hash
  } else {
    recreated_datum.event_creation_info == datum.event_creation_info
  }
}

fn to_object_datum(data: Data) -> ObjectDatum {
  expect my_datum: ObjectDatum = data
  my_datum
}

test must_cast_to_stake_pool_datum() {
  let object_datum =
    ObjectDatum {
      protocol_version: 1,
      data_reference: "ref",
      event_creation_info: "",
      signers: [
        #"ad729530bbd009ad5e38034be47dc1f5b93b4ffeafa2963b4ef9846c",
        #"b6d8be69da875267f9acf095456627153a88e08997c371d66f524b46",
      ],
    }
  let object_data: Data = object_datum
  object_datum == to_object_datum(object_data)
}
