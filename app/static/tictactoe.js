
let board = ["", "", "", "", "", "", "", "", ""];
let currentPlayer = "X";
let active = true;

const statusText = document.getElementById("status");
const cells = document.querySelectorAll(".cell");

const winningPatterns = [
    [0,1,2],
    [3,4,5],
    [6,7,8],
    [0,3,6],
    [1,4,7],
    [2,5,8],
    [0,4,8],
    [2,4,6]
];

cells.forEach(cell => cell.addEventListener("click", cellClicked));

function cellClicked() {
    const index = this.getAttribute("data-index");

    if (board[index] !== "" || !active) return;

    board[index] = currentPlayer;
    this.textContent = currentPlayer;

    checkWinner();
}

function checkWinner() {
    let roundWon = false;

    for (let pattern of winningPatterns) {
        const [a, b, c] = pattern;

        if (board[a] && board[a] === board[b] && board[a] === board[c]) {
            roundWon = true;
            break;
        }
    }

    if (roundWon) {
        statusText.textContent = `🎉 Player ${currentPlayer} Wins!`;
        active = false;
        return;
    }

    if (!board.includes("")) {
        statusText.textContent = "😮 It's a Draw!";
        active = false;
        return;
    }

    currentPlayer = currentPlayer === "X" ? "O" : "X";
    statusText.textContent = `Player ${currentPlayer}'s turn`;
}

function restartGame() {
    board = ["", "", "", "", "", "", "", "", ""];
    currentPlayer = "X";
    active = true;
    statusText.textContent = `Player X's turn`;
    cells.forEach(cell => cell.textContent = "");
}
