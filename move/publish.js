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

const compiledModulesAndDeps = JSON.parse(
  execSync(`sui move build --dump-bytecode-as-base64 --path ${packagePath}`, {
    encoding: "utf-8",
  })
);

(async () => {
  // publish the module
  let result = await (async function publish() {
    console.log("HI!")
    const tx = new sdk.TransactionBlock();
    console.log("HI2!")
    const [upgradeCap] = tx.publish(
      compiledModulesAndDeps.modules.map((m) => Array.from(sdk.fromB64(m))),
      compiledModulesAndDeps.dependencies.map((addr) =>
        sdk.normalizeSuiObjectId(addr)
      )
    );

    console.log("HI3");

    tx.transferObjects([upgradeCap], tx.pure(await signer.getAddress()));

    const result = await signer.signAndExecuteTransactionBlock(
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

    console.log("EXECUTE RESULT", JSON.stringify(result, null, 4));

    let chg = result.objectChanges;
    let item = chg.find((r) => r.type == "created" && r.objectType.includes("Item"));

    return [
      chg.find((r) => r.type == "published").packageId,
      chg.find((r) => r.type == "created" && r.objectType.includes("Publisher")).objectId,
      item.objectId,
      item.objectType
    ];
  })();

  console.log("RESULT", JSON.stringify(result, null, 4));
  // const [_pkg, publisher, item, itemType] = result;
  return result;
})();