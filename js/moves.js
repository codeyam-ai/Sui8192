const { ethos } = require("ethos-wallet-beta");
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

const constructTransaction = (direction, activeGameAddress) => {
  return {
    network: 'sui',
    address: contractAddress,
    moduleName: 'game_8192',
    functionName: 'make_move',
    inputValues: [
      activeGameAddress,
      direction
    ],
    gasBudget: 100000
  }
}

const checkPreapprovals = async (activeGameAddress, walletSigner) => {
  // if (preapproval === undefined) {
    try {
      const result = await ethos.requestPreapproval({
        signer: walletSigner,
        preapproval: {
          packageObjectId: contractAddress,
          objectId: activeGameAddress,
          module: 'game_8192',
          function: 'make_move',
          description: "Pre-approve moves in the game so you can play without signing every transaction.",
          totalGasLimit: 100000,
          perTransactionGasLimit: 5000,
          maxTransactionCount: 20
        }
      })

      preapproval = result.approved;
    } catch (e) {
      console.log("Error requesting preapproval", e);
      preapproval = false;
    }
  // }
  
  return preapproval;
}

const load = async (walletSigner, activeGameAddress, onComplete, onError) => {
  if (walletSigner.extension) {
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

  ethos.transact({
    id: "load-moves",
    signer: walletSigner,
    details: {
      network: 'sui',
      signOnly: true,
      transactions: transactions
    }, 
    onPopulated({ data }) {
      if (data.error) {
        onError();
        return;
      }
      
      for (const { id: direction, transaction } of data.transactions) {
        moves[direction] = {
          ...(moves[direction] || {}),
          populatedTransaction: transaction
        }
      }
    },
    onSigned({ data }) {
      if (data.error) {
        onError();
        return;
      }
      for (const { id: direction, transaction } of data.transactions) {
        moves[direction] = {
          ...(moves[direction] || {}),
          signedTransaction: transaction
        }
      }
    },
    onCompleted() {
      const queuedMove = queue.next()
      if (queuedMove) execute(queuedMove, activeGameAddress, walletSigner, onComplete, onError);
    }
  });
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
  
  let details;

  if (!walletSigner.extension) {
    if (!move?.populatedTransaction || !move?.signedTransaction) {
      if (!directionOrQueuedMove.id) {
        queue.add(direction);
      }
      return;
    }  

    details = {
      network: 'sui',
      signedInfo: move
    } 
  } else {
    details = constructTransaction(directionNumber, activeGameAddress)
  }

  moves = {};

  ethos.transact({
    id: 'move',
    signer: walletSigner, 
    details,
    onCompleted: async ({ data }) => {
      if (directionOrQueuedMove.id) {
        queue.remove(directionOrQueuedMove);
      }
      
      load(walletSigner, activeGameAddress, onComplete, onError);

      if (data.error || data?.effects?.status?.error === "InsufficientGas") {
        onError();
        return;
      }

      if (!data) return;
      const { effects } = data;
      const { gasUsed, events} = effects;
      const { computationCost, storageCost, storageRebate } = gasUsed;
      const event = events[0].moveEvent;
      
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
          <div>
            <span class="light">
              New Tile:
            </span>
            <span class="">
              ${transaction.lastTile.row}, ${transaction.lastTile.column}
            </span>
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
    }
  })

  ethos.hideWallet();
}

const reset = () => moves = []

module.exports = {
  constructTransaction,
  load,
  execute,
  reset
};