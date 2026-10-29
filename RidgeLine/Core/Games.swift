import Foundation

extension Starter {
    /// Campsite games, mostly with a deck of cards. Rules are the common "house" versions.
    static func games() -> [GameItem] {
        func game(_ id: String, _ name: String, _ kind: String, _ players: String, _ minutes: Int,
                  bring: String, overview: String, rules: [String], tip: String) -> GameItem {
            GameItem(id: id, name: name, kind: kind, players: players, minutes: minutes,
                     bring: bring, overview: overview, rules: rules, tip: tip)
        }

        return [
            game("gin-rummy", "Gin Rummy", "Card game", "2", 25,
                 bring: "1 standard 52-card deck",
                 overview: "The classic two-player rummy game. Build sets and runs, and go out with the fewest leftover points.",
                 rules: [
                    "Deal 10 cards each. Turn one card face up to start the discard pile; the rest is the draw pile.",
                    "Melds are sets (3–4 cards of one rank) or runs (3+ consecutive cards of one suit). Aces are low only.",
                    "Card values: Ace = 1, number cards = face value, J/Q/K = 10. Cards not in melds are your deadwood.",
                    "On your turn, draw the top of either pile, then discard one card.",
                    "You may knock (end the hand) when your deadwood totals 10 or less after discarding. If all 10 cards are melded, that's Gin.",
                    "After a knock, the other player lays off any of their cards onto your melds, then both count deadwood.",
                    "If your deadwood is lower, you score the difference. If theirs is equal or lower, they 'undercut' and score the difference plus 25.",
                    "Gin scores 25 plus the other player's deadwood. First to 100 points wins."
                 ],
                 tip: "Keep a flexible hand of nearly-complete melds and note which cards the other player picks up."),

            game("cribbage", "Cribbage", "Card game + board", "2", 30,
                 bring: "1 deck, cribbage board with pegs",
                 overview: "A pegging race to 121 points. Great with a travel board on the tailgate.",
                 rules: [
                    "Deal 6 cards each. Each player discards 2 face-down into the 'crib', which belongs to the dealer.",
                    "The non-dealer cuts the deck; the dealer turns up the top card as the starter. If it's a Jack, the dealer pegs 2.",
                    "The Pegging: starting with the non-dealer, players take turns laying one card and calling the running total (face cards = 10, Ace = 1). The total may not pass 31.",
                    "Pegging points: total of exactly 15 = 2, exactly 31 = 2, pair = 2, three of a kind = 6, four = 12, run of 3+ in any order = its length. 'Go' (last card before 31, or a player who can't play) = 1.",
                    "Counting hands (non-dealer first, then dealer, then the crib): each combination adding to 15 = 2, each pair = 2, each run = its length, a four-card flush in hand = 4 (5 with the starter), and a Jack matching the starter's suit = 1 ('nobs').",
                    "Peg your points on the board as you score. First to 121 wins."
                 ],
                 tip: "Throw cards to the crib that don't help the opponent's score when it's their crib (keep fives out of it!)."),

            game("crazy-eights", "Crazy Eights", "Card game", "2–5", 15,
                 bring: "1 standard 52-card deck",
                 overview: "Match the top card by suit or number. Eights are wild.",
                 rules: [
                    "Deal 7 cards each for two players (5 each for 3–5 players). Turn one card up to start the discard pile.",
                    "On your turn, play a card that matches the top discard by suit or by rank.",
                    "Eights are wild: play one at any time and name the suit the next player must follow.",
                    "If you can't play, draw from the pile until you can (or draw one and pass, if you prefer a faster game).",
                    "First player to get rid of all their cards wins the hand.",
                    "To keep score, the winner collects points for cards left in the others' hands: 8 = 50, face cards = 10, Ace = 1, others = face value. First to 100 wins."
                 ],
                 tip: "Save an eight for when you're stuck — it's your get-out-of-jail card."),

            game("go-fish", "Go Fish", "Card game", "2–4", 15,
                 bring: "1 standard 52-card deck",
                 overview: "Collect sets of four by asking the other player for ranks. Easy and silly.",
                 rules: [
                    "Deal 7 cards each for two players (5 for 3–4 players). Put the rest face-down as the 'pond'.",
                    "On your turn, ask the other player for a rank you hold: 'Do you have any sevens?'",
                    "If they have any, they must give you all of them, and you ask again.",
                    "If not, they say 'Go fish!' and you draw one card from the pond. If it's the rank you asked for, show it and go again; otherwise your turn ends.",
                    "Whenever you hold all four cards of a rank, lay them down as a 'book'.",
                    "If you run out of cards, draw from the pond. The game ends when all 13 books are made — most books wins."
                 ],
                 tip: "Ask for ranks you already hold, and remember what the other player asked for."),

            game("golf", "Golf", "Card game", "2–4", 20,
                 bring: "1 standard 52-card deck, pencil and paper",
                 overview: "Lowest score wins over nine 'holes'. Swap cards to build a low hand.",
                 rules: [
                    "Deal 6 cards face-down to each player in a 2×3 grid. Turn one card up to start the discard pile.",
                    "Each player flips over any 2 of their cards to start.",
                    "On your turn, draw the top card of either pile. Swap it with any one of your six cards (the replaced card goes to the discard pile), or discard it — if you drew from the draw pile and discard it, flip one of your face-down cards.",
                    "Card values: Ace = 1, 2 = −2, 3–10 = face value, Jack and Queen = 10, King = 0.",
                    "Two cards of the same rank in the same column cancel out (score 0 for the pair).",
                    "When one player has all six cards face-up, everyone else gets one last turn. Then everyone flips their cards and scores.",
                    "Play nine hands ('holes'). Lowest total score wins."
                 ],
                 tip: "Chase a column of matching cards; kings and twos are gold."),

            game("kings-corner", "Kings in the Corner", "Card game", "2–4", 20,
                 bring: "1 standard 52-card deck",
                 overview: "Build descending, alternating-color piles in a cross shape around the draw pile. First empty hand wins.",
                 rules: [
                    "Deal 7 cards each. Place the draw pile in the center and turn four cards face-up above, below, left and right of it. These are the four starting piles.",
                    "On your turn, draw one card, then play as many cards as you can.",
                    "Build each pile downward in alternating colors (a red 6 goes on a black 7, and so on).",
                    "You can move a whole pile onto another if its top card legally fits on the other pile's bottom card.",
                    "Kings may only be placed in the four corner spots (diagonal to the center), where they start new piles. Any card can fill an empty spot in the cross.",
                    "When you can't or don't want to play more, your turn ends.",
                    "First player to empty their hand wins. The others score the cards left in their hand (house rule: 1 point each, kings count 10)."
                 ],
                 tip: "Don't be in a hurry to place kings — you can't win without opening corner space."),

            game("war", "War", "Card game", "2", 15,
                 bring: "1 standard 52-card deck",
                 overview: "A no-brainer game for lazy tent evenings. Luck decides everything — great with coffee.",
                 rules: [
                    "Deal the whole deck evenly, face-down. Players don't look at their cards.",
                    "Each player flips their top card at the same time. The higher card (Ace high) wins both cards, which go to the bottom of that player's pile.",
                    "On a tie, it's 'war': each player lays three cards face-down and a fourth face-up. The higher fourth card wins all ten cards.",
                    "If the new cards tie again, repeat the war.",
                    "The first player to collect the whole deck wins."
                 ],
                 tip: "Set a time limit — War can last a very long time."),

            game("blackjack", "Blackjack (21)", "Card game", "2+", 15,
                 bring: "1 standard 52-card deck, pebbles or candy for chips",
                 overview: "Beat the dealer by getting closer to 21 without going over. Bet with M&Ms or pebbles.",
                 rules: [
                    "One player is the dealer; swap dealers each round. Everyone else bets first.",
                    "Deal two cards to each player face-up and two to the dealer (one face-up, one face-down).",
                    "Card values: number cards = face value, face cards = 10, Ace = 1 or 11.",
                    "On your turn, 'hit' to take another card or 'stand' to stop. If you go over 21, you bust and lose your bet.",
                    "After the players, the dealer reveals their card and must hit until they reach 17 or more.",
                    "If the dealer busts or has a lower total than you, you win your bet. A tie ('push') returns your bet.",
                    "A natural 21 on your first two cards (an Ace and a ten-value card) pays 3 to 2."
                 ],
                 tip: "Agree on the stakes before dealing — candy is a great currency."),

            game("farkle", "Farkle", "Dice game", "2+", 20,
                 bring: "6 dice, a cup, pencil and paper",
                 overview: "Push your luck: keep rolling for points, but one bad roll wipes out your turn.",
                 rules: [
                    "On your turn, roll all six dice. You need at least one scoring die or combo; otherwise it's a 'Farkle' and you score nothing for the turn.",
                    "Set aside scoring dice, then either bank your points or re-roll the remaining dice (you must set aside at least one scoring die each roll).",
                    "Scoring: single 1 = 100, single 5 = 50. Three 1s = 1,000; three 2s = 200; three 3s = 300; three 4s = 400; three 5s = 500; three 6s = 600.",
                    "Four of a kind = 1,000; five of a kind = 2,000; six of a kind = 3,000; a 1–6 straight = 1,500; three pairs = 1,500.",
                    "If all six dice score, you have 'hot dice' — pick them all up and keep rolling.",
                    "Many groups require 500 points in one turn before you can start banking. Agree on this house rule before you start.",
                    "First to 10,000 wins. Once someone reaches 10,000, everyone else gets one last turn."
                 ],
                 tip: "Quit while you're ahead — three or fewer dice left is risky."),

            game("dominoes", "Dominoes (Block Game)", "Tile game", "2–4", 20,
                 bring: "1 double-six domino set",
                 overview: "The classic matching game: play all your tiles first.",
                 rules: [
                    "Shuffle the tiles face-down. Each player draws 7 (for two players, the rest form the boneyard).",
                    "The player with the highest double starts. Otherwise the highest-pip tile leads.",
                    "Players take turns playing a tile with a matching number at one of the open ends.",
                    "If you can't play, draw from the boneyard until you can; if it's empty, you pass.",
                    "The first player to play all their tiles wins and scores the total of the other player's remaining pips.",
                    "If nobody can play (the game is blocked), the lowest pip total wins and scores the difference.",
                    "First to 100 points wins the match."
                 ],
                 tip: "Hold on to doubles — they're hard to play late."),

            game("twenty-questions", "Twenty Questions", "No props", "2+", 10,
                 bring: "Nothing",
                 overview: "Great for night drives or sitting by the fire.",
                 rules: [
                    "One player thinks of something — a person, place, or thing — and says if it's Animal, Vegetable, or Mineral.",
                    "The others take turns asking yes-or-no questions to figure out what it is.",
                    "Count each question out loud. If the guessers solve it in 20 questions or fewer, they win. If not, the thinker wins.",
                    "The winner chooses the next secret."
                 ],
                 tip: "Pick things you can see from camp so the game stays fun."),

            game("two-truths", "Two Truths and a Lie", "No props", "2+", 15,
                 bring: "Nothing",
                 overview: "Say three things about yourself; the other person guesses which is the lie.",
                 rules: [
                    "One player says three statements about themselves — two true and one false.",
                    "The other player guesses which one is the lie.",
                    "Reveal the answer, then swap roles.",
                    "Keep score if you like: one point for each right guess."
                 ],
                 tip: "On a trip, try 'stories from the trail' as the theme.")
        ]
    }
}
