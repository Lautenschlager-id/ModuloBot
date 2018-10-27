## Properties
| Name | Type | Description |
|-|-|-|
| authorId | string|int | The id of the user that ran **!lua**. |
| authorName | string | The name and discriminator of the user that ran **!lua**. |
| messageId | string|int | The id of the script message from **!lua**. |
## Static Methods
### delete(msgId)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| msgId | `string` \| `int` |  |
>
>Deletes a message sent by the bot.

### http(url, header, body, token)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| url | `string` |  |
>| header | `table` | ✔ |
>| body | `string` | ✔ |
>| token | `string` \| `table` | ✔ |
>
>Performs a GET HTTP request.

### reply(text)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| text | `string` \| `table` |  |
>
>Sends a message in the channel.
>
>**Returns:** `string` | `int` | `boolean`

### sendError(command, err, description)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| command | `string` |  |
>| err | `string` |  |
>| description | `string` | ✔ |
>
>Sends an error message in the channel.

### load(src)
>| Parameter | Type | Optional |
>|-|-|:-:|
>| src | `string` |  |
>
>Loads a Lua code given in a string.
>
>**Returns:** `function`
