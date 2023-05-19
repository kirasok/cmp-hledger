# cmp-hledger

[nvim-cmp](https://github.com/hrsh7th/nvim-cmp) source for [hledger](https://hledger.org/) accounts.

cmp-hledger completes based on prefix and prefix abbreviation (e.g. `E:D:C` to `Expenses:Drinks:Coffee`) of hledger account names.

## Setup

Prerequisites:

```shell
yay -S neovim hledger
```

Install with your favorite package manager:

```lua
use('kirasok/cmp-hledger')
```

Then, setup completion source:

```lua
require('cmp').setup {
  sources = {
    {
      name = 'hledger',
    }
  }
}
```

## [ledger](https://github.com/ledger/ledger) support

Plugin will choose to work with `ledger` if it won't find `hledger` binary in `PATH`.

## License

Source code available under [GNU GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses).

## Credits

Thanks [cmp-beancount](https://github.com/crispgm/cmp-beancount) for providng example of making [cmp](https://github.com/hrsh7th/nvim-cmp) source.
