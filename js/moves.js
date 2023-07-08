const { ethos, TransactionBlock } = require("ethos-connect");
const {
  eById,
  addClass,
  removeClass,
  directionToDirectionNumber,
  directionNumberToSymbol,
} = require("./utils");
const board = require("./board");
const queue = require("./queue");

let moves = {};
let preapproval;
let preapprovalNotified = false;
let executingMove = false;
const responseTimes = {
  total: 0,
  count: 0,
  start: null,
}

const constructTransaction = (direction, activeGameAddress, contractAddress) => {
  const transactionBlock = new TransactionBlock();
  transactionBlock.moveCall({
    target: `${contractAddress}::game_8192::make_move`,
    arguments: [
      transactionBlock.object(activeGameAddress),
      transactionBlock.pure(direction)
    ]
  })
  return transactionBlock;
};

const checkPreapprovals = async (chain, contractAddress, activeGameAddress, walletSigner) => {
  if (walletSigner.type === "hosted") {
    return true;
  }

  try {
    const result = await ethos.preapprove({
      signer: walletSigner,
      preapproval: {
        target: `${contractAddress}::game_8192::make_move`,
        chain,
        objectId: activeGameAddress,
        description:
          "Pre-approve moves in the game so you can play without signing every transaction.",
        totalGasLimit: 50000000,
        maxTransactionCount: 25,
      },
    });

    preapproval = result.approved;
  } catch (e) {
    console.log("Error requesting preapproval", e);
    preapproval = false;
  }

  if (!preapprovalNotified && !preapproval) {
    removeClass(eById("preapproval"), "hidden");
    preapprovalNotified = true;
  }

  return preapproval;
};

const checkValidMove = (packedSpaces, directionNumber) => {
  // console.log("checkValidMove", packedSpaces, directionNumber)
  const direction = parseInt(directionNumber)
  let validMove = false;
  for (let i=0; i<board.ROWS; ++i) {
    for (let j=0; j<board.COLUMNS; ++j) { 
      const tile = board.spaceAt(packedSpaces, i, j);
      const nextI = direction > 1 ? i + (direction === 2 ? -1 : 1) : i;
      const nextJ = direction < 2 ? j + (direction === 0 ? -1 : 1) : j;
      const nextTile = board.spaceAt(packedSpaces, nextI, nextJ);
      // console.log(i, j, nextI, nextJ, tile, nextTile)

      if (parseInt(tile) === 0) continue;
      if (nextI === -1 || nextI >= board.ROWS) continue;
      if (nextJ === -1 || nextJ >= board.COLUMNS) continue;
      if (parseInt(nextTile) !== 0 && parseInt(tile) !== parseInt(nextTile)) {
        continue
      }

      validMove = true;
      break;
    }
  }

  // console.log("valid move", validMove);
  return validMove
}
window.checkValidMove = checkValidMove;

const execute = async (
  chain,
  originalContractAddress,
  contractAddress,
  directionOrQueuedMove,
  activeGameAddress,
  walletSigner,
  onComplete,
  onError
) => {
  if (executingMove) return;

  executingMove = true;

  if (board.active().gameOver) {
    onError({ gameOver: true });
    return;
  }

  await checkPreapprovals(chain, contractAddress, activeGameAddress, walletSigner);

  const direction = directionOrQueuedMove.id
    ? directionOrQueuedMove.direction
    : directionOrQueuedMove;

  const directionNumber = directionToDirectionNumber(direction);
  
  const { packedSpaces } = board.active();
  const validMove = checkValidMove(packedSpaces, directionNumber);
  if (!validMove) {
    moves = {};
    executingMove = false;
    return;
  }
  
  if (responseTimes.count > 0 && (responseTimes.total / responseTimes.count) > 1000) {
    if (!directionOrQueuedMove.id) {
      directionOrQueuedMove = queue.add(direction);
    }

    if (queue.length() > 1) return;
  }
  
  const moveTransaction = constructTransaction(
    directionNumber,
    activeGameAddress,
    contractAddress
  );

  moves = {};

  const dataPromise = ethos.transact({
    signer: walletSigner,
    transactionInput: {
      transactionBlock: moveTransaction,
      chain,
      options: {
        showEvents: true,
        showEffects: true
      },
      requestType: 'WaitForLocalExecution'
    }
  });

  ethos.hideWallet(walletSigner);

  let data;
  try {
    responseTimes.start = Date.now();

    data = await dataPromise;

    responseTimes.total += Date.now() - responseTimes.start;
    responseTimes.count += 1;
  } catch (e) {
    onError({ error: e.message });
  } finally {
    executingMove = false;
  }

  if (!data) return;

  const { events, effects } = data;

  queue.remove(directionOrQueuedMove);
  
  if (effects?.status?.error === "InsufficientGas") {
    onError({ error: "Insufficient gas" });
    return;
  }

  if (
    (effects?.status?.error || "").indexOf(
      'name: Identifier("game_board_8192") }, function: 17, instruction: 8 }, 3)'
    ) > -1
  ) {
    onError({ gameOver: true });
    return;
  }

  if (effects?.status?.error) {
    const { error } = effects.status;
    onError({ error });
    return;
  }

  if (!effects) return;

  const { gasUsed } = effects;
  const { computationCost, storageCost, storageRebate } = gasUsed;
  const event = events.find((e) => e.type === `${originalContractAddress}::game_8192::GameMoveEvent8192`)

  const newBoard = board.convertInfo(event);

  if (newBoard.gameOver) {
    onError({ gameOver: true });
    return;
  }

  onComplete(newBoard, direction);

  const { direction: lastDirection, last_tile: lastTile, move_count: moveCount } = event.parsedJson;
  const transaction = {
    gas: BigInt(computationCost) + BigInt(storageCost) - BigInt(storageRebate),
    computation: computationCost,
    storage: BigInt(storageCost) - BigInt(storageRebate),
    move: lastDirection,
    lastTile,
    moveCount
  };
  const transactionElement = document.createElement("DIV");
  addClass(transactionElement, "transaction");
  transactionElement.innerHTML = `
    <div class='transaction-left'>
      <div class='transaction-count'>
        ${parseInt(transaction.moveCount) + 1}
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

  eById("transactions-list").prepend(transactionElement);
  removeClass(eById("transactions"), "hidden");

  if (queue.length() > 0) {
    const queuedMove = queue.next()
    execute(
      queuedMove,
      activeGameAddress,
      walletSigner,
      onComplete,
      onError
    )
  }
};

const reset = () => (moves = []);

module.exports = {
  checkPreapprovals,
  constructTransaction,
  execute,
  reset,
};
