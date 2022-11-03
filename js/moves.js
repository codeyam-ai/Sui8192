const { ethos } = require("ethos-connect");
const { contractAddress } = require("./constants");
const { 
  eById, 
  addClass, 
  removeClass,
  directionToDirectionNumber,
  directionNumberToSymbol
} = require('./utils');
const board = require('./board');
const queue = require('./queue');

let moves = {};
let preapproval;
let preapprovalNotified = false;

const constructTransaction = (direction, activeGameAddress) => {
  return {
    kind: "moveCall",
    data: {
      packageObjectId: contractAddress,
      module: 'game_8192',
      function: 'make_move',
      typeArguments: [],
      arguments: [
        activeGameAddress,
        direction
      ],
      gasBudget: 50000
    }
  }
}

const checkPreapprovals = async (activeGameAddress, walletSigner) => {
    if (walletSigner.type === 'ethos_hosted') {
        return true;
    }

  // if (preapproval === undefined) {
    try {
      const result = await ethos.preapprove({
        signer: walletSigner,
        preapproval: {
          packageObjectId: contractAddress,
          objectId: activeGameAddress,
          module: 'game_8192',
          function: 'make_move',
          description: "Pre-approve moves in the game so you can play without signing every transaction.",
          totalGasLimit: 500000,
          maxTransactionCount: 25
        }
      })

      preapproval = result.approved;
    } catch (e) {
      console.log("Error requesting preapproval", e);
      preapproval = false;
    }
  // }

  if (!preapprovalNotified && !preapproval) {
    removeClass(eById('preapproval'), 'hidden');
    preapprovalNotified = true
  }
  
  return preapproval;
}

const load = async (walletSigner, activeGameAddress, onComplete, onError) => {
  return;
  if (walletSigner.type === "extension") {
    return;
  } 

  const directions = ["0", "1", "2", "3"];

  if (Object.keys(moves).length === directions.length) {
    return;
  }

  const transactions = []
  for (const direction of directions) {
    const transaction = constructTransaction(direction, activeGameAddress);
    transaction.id = direction;
    transactions.push(transaction);
  }

  const { data } = await ethos.sign({
    signer: walletSigner,
    signableTransactions: transactions
  })
  //     , 
  //   onPopulated({ data }) {
  //     if (data.error) {
  //       onError(data.error);
  //       return;
  //     }
      
  //     for (const { id: direction, transaction } of data.transactions) {
  //       moves[direction] = {
  //         ...(moves[direction] || {}),
  //         populatedTransaction: transaction
  //       }
  //     }
  //   },
  //   onSigned({ data }) {
  //     if (data.error) {
  //       onError();
  //       return;
  //     }
  //     for (const { id: direction, transaction } of data.transactions) {
  //       moves[direction] = {
  //         ...(moves[direction] || {}),
  //         signedTransaction: transaction
  //       }
  //     }
  //   },
  //   onCompleted() {
  //     const queuedMove = queue.next()
  //     if (queuedMove) execute(queuedMove, activeGameAddress, walletSigner, onComplete, onError);
  //   }
  // });
  ethos.hideWallet();
}

const execute = async (directionOrQueuedMove, activeGameAddress, walletSigner, onComplete, onError) => {
  if (board.active().gameOver) return;

  await checkPreapprovals(activeGameAddress, walletSigner);

  const direction = directionOrQueuedMove.id ? 
    directionOrQueuedMove.direction : 
    directionOrQueuedMove;

  const directionNumber = directionToDirectionNumber(direction);
  const move = moves[directionNumber];
  
  let signableTransaction;

  if (false && walletSigner.type === "ethos_hosted") {
    if (!move?.populatedTransaction || !move?.signedTransaction) {
      if (!directionOrQueuedMove.id) {
        queue.add(direction);
      }
      return;
    }  

    signableTransaction = {
      signedInfo: move
    } 
  } else {
    signableTransaction = constructTransaction(directionNumber, activeGameAddress)
  }

  moves = {};

  const dataPromise = ethos.transact({
    signer: walletSigner, 
    signableTransaction,
  })
  
  ethos.hideWallet();

  const data = await dataPromise;

  const { error, effects } = data.EffectsCert || data;

  if (directionOrQueuedMove.id) {
    queue.remove(directionOrQueuedMove);
  }
  
  load(walletSigner, activeGameAddress, onComplete, onError);
  
  if ((effects.effects || effects)?.status?.error === "InsufficientGas") {
    onError()
    return;
  }

  if (error) {
    onError(error);
    return;
  }

  if (!effects) return;
  const { gasUsed, events} = effects.effects || effects;
  const { computationCost, storageCost, storageRebate } = gasUsed;
  const event = events.find((e) => e.moveEvent).moveEvent;
  
  onComplete(board.convertInfo(event), direction);
  
  const { fields } = event;
  const { last_tile: lastTile } = fields;
  const transaction = {
    gas: computationCost + storageCost - storageRebate,
    computation: computationCost,
    storage: storageCost - storageRebate,
    move: fields.direction,
    lastTile: {
      row: lastTile[0],
      column: fields.last_tile[1]
    },
    moveCount: fields.move_count
  };
  const transactionElement = document.createElement("DIV");
  addClass(transactionElement, 'transaction');
  transactionElement.innerHTML = `
    <div class='transaction-left'>
      <div class='transaction-count'>
        ${transaction.moveCount + 1}
      </div>
      <div class='transaction-direction'>
        ${directionNumberToSymbol(transaction.move.toString())}
      </div>
    </div>
    <div class="transaction-right">
      <div class=''>
        <span class="light">
          Computation:
        </span>
        <span>
          ${transaction.computation}
        </span>
      </div>
      <div class=''>
        <span class="light">
          Storage:
        </span>
        <span>
          ${transaction.storage}
        </span>
      </div>
      <div class=''>
        <span class='light'>
          Gas:
        </span>
        <span class=''>
          ${transaction.gas}
        </span>
      </div>
    </div>
  `;

  eById('transactions-list').prepend(transactionElement);
  removeClass(eById('transactions'), 'hidden');

  ethos.hideWallet();
}

const reset = () => moves = []

module.exports = {
  checkPreapprovals,
  constructTransaction,
  load,
  execute,
  reset
};