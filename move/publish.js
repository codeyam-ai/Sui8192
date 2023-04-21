const sdk = require("@mysten/sui.js");
const { execSync } = require("child_process");
const path = require("path");
const packagePath = path.resolve(__dirname);

if (!process.env.MNEMONIC) {
  console.log('Requires MNEMONIC; set with `export MNEMONIC="..."`');
  process.exit(1);
}

const keypair = sdk.Ed25519Keypair.deriveKeypair(process.env.MNEMONIC);
const provider = new sdk.JsonRpcProvider(new sdk.Connection({ fullnode: 'https://fullnode.testnet.sui.io/' }));
const signer = new sdk.RawSigner(keypair, provider);

const { modules, dependencies } = JSON.parse(
  execSync(
      `sui move build --dump-bytecode-as-base64 --path ${packagePath}`,
      { encoding: "utf-8" }
  )
);

(async () => {
  // publish the module
  let result = await (async function publish() {
    const tx = new sdk.TransactionBlock();
    const [upgradeCap] = tx.publish({
        modules,
        dependencies,
    });

    tx.transferObjects([upgradeCap], tx.pure(await signer.getAddress()));

    let result;
    try {
        result = await signer.signAndExecuteTransactionBlock(
        {
            transactionBlock: tx,
            options: {
            showEffects: true,
            showObjectChanges: true,
            showEvents: true,
            },
        },
        "WaitForLocalExecution"
        );
    } catch (e) {
        console.log("Error publishing: ", e);
        process.exit(1);
    }

    console.log("EXECUTE RESULT", JSON.stringify(result, null, 4));
  })();

  // console.log("RESULT", JSON.stringify(result, null, 4));
  // const [_pkg, publisher, item, itemType] = result;
  return result;
})();