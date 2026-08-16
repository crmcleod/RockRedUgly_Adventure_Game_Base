# How to...
## Dialogue
<details>
<summary>
Basic example, nested objects. 
</summary>
Entry point always "start", although technically configurable which allows alternative conditional entry points outside of the dialogue:

```
{
	"start": {
		"speaker": "player",
		"text": "Hi",
		"next": "next_reference"
	},
	"next_reference": {...}
}
```
</details

<details>
<summary>
Basic conditional
</summary>

In this example, the text will always play on the "start" block. The "condition" is used to check the game state, if it is already flagged, then we move to the "conditional next", otherwise the "next". In the standard "next" block we use the ```"set_flag": "already_spoken"``` so in a repeated conversation the condition would be triggered.

```
{
	"start": {
		"speaker": "player",
		"text": "Have we spoken before?",
		"condition": "already_spoken",
		"conditional_next": "already_spoken",
		"next": "first_time_speaking"
	},
	"first_time_speaking": {
		"speaker": "npc",
		"text": "No",
		"set_flag": "already_spoken"
	},
	"already_spoken": {
		"speaker": "npc",
		"text": "Yes"
	}
}
```

</details>

<details>
<summary>
Override condition
</summary>
Technically you can use a block with no speaker or text AND a conditional_check to achieve the same thing, but this is more explicit. The override will prevent the standard conditional_check and force the conversation to begin or continue at a different point without the current text being said. It won't override a "set_flag" so be careful

```
{
  "start": {
	"speaker": "npc",
	"text": "Hello, sir",
	"next": "tg_check_progress",
	"override": {
		"dialogue_condition": "fair_paid",
		"next": "fair_paid"
	}
  }
}
```
</details>

<details>
<summary>
Conversational choices
</summary>
Does what it says on the tin really

```
 "bp_q1": {
	"condition": "bp_q1",
	"conditional_next": "bp_q2",
	"speaker": "player",
	"choices": [
	  { "text": "Know anything with a tune?", "next": "polite" },
	  { "text": "I'll give you one dollar to shut the hell up", "next": "rude" }
	]
  }
```
</details>

<details>
<summary>
One liners...
</summary>

```fade: true``` will trigger a quick fade to black and back

```update_animation: "animation_name"``` will switch the main players animation

```receive_item: "notepad"``` will add an item to the inventory

</details>
