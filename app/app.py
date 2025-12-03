from flask import Flask, render_template, request, session, redirect, url_for
import random

app = Flask(__name__)
app.secret_key = "supersecretkey"

# --------------------------
# HOME: GAME HUB
# --------------------------
@app.route("/")
def home():
    return render_template("home.html")


# --------------------------
# GUESS THE NUMBER GAME
# --------------------------
@app.route("/guess", methods=["GET", "POST"])
def guess_game():
    # Initialize level & high score
    if "high_score" not in session:
        session["high_score"] = None

    if "level" not in session:
        session["level"] = 1

    max_number = session["level"] * 20  # Difficulty increases

    if "number" not in session:
        session["number"] = random.randint(1, max_number)
        session["attempts"] = 0

    message = ""

    if request.method == "POST":
        guess = int(request.form["guess"])
        session["attempts"] += 1
        number = session["number"]

        if guess < number:
            message = "⬇ Too low!"
        elif guess > number:
            message = "⬆ Too high!"
        else:
            message = f"🎉 Correct! The number was {number}."

            # High score logic
            if session["high_score"] is None or session["attempts"] < session["high_score"]:
                session["high_score"] = session["attempts"]

            # Move to next level
            session["level"] += 1
            session.pop("number")
            session.pop("attempts")

    return render_template("guess.html",
                           message=message,
                           level=session["level"],
                           high_score=session["high_score"],
                           max_number=max_number)


# ------------------------------
# RESET GAME
# ------------------------------
@app.route("/reset")
def reset():
    session.clear()
    return redirect(url_for("guess_game"))


@app.route("/tic-tac-toe")
def tic_tac_toe():
    return render_template("tictactoe.html")



if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
