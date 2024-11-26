# ha-notifier

A simple daemon for Linux or macOS which listens for Home Assistant
notifications via the REST integration and displays them via `notify-send`, with
rich options.

## Requirements

The receiving device needs `libnotify`, specifically the `notify-send` command.
If you can run `which notify-send` in a terminal and get a path back, you're
good to go.

## Setup

### Client

#### Nix Home Manager

I have tested this on my own machine running NixOS with Home Manager via Flakes.
Add the input to your flake:

```nix
inputs = {
  ha-notifier.url = "github:cvincent/ha-notifier";
};
```

Then, somewhere in your Home Assistant configuration:

```nix
{
  imports = [ inputs.ha-notifier.homeManagerModules.default ];
  services.ha-notifier.enable = true;
}
```

To customize the port:

```nix
{
  imports = [ inputs.ha-notifier.homeManagerModules.default ];
  services.ha-notifier = {
    enable = true;
    port = 1234;
  };
}
```

This should then run as a systemd user service when you log in. You may need to
start it manually when you first install it:

```sh
systemctl --user start ha-notifier.service
```

### Home Assistant

Home Assistant needs a REST target to which to send your notifications. In your
`configuration.yaml`, add the following:

```yml
notify:
  - name: my_laptop
    platform: rest
    resource: http://[LAN IP]:[port]/notifications
    title_param_name: title
    target_param_name: target
    data:
      data: '{{ data }}'
```

Pick any `name` you like. `[LAN IP]` is the IP of the machine which will be
running `ha-notifier` and receiving notifications. `[port]` can be any port you
like; by default, `ha-notifier` uses port 8124.

Then you can set up notifications in your automations. Here's an example:

```yml
action: notify.my_laptop
metadata: {}
data:
  title: Notification title
  message: Notification message
  data:
    icon: dialog-information
    urgency: 2
    sound: /home/my_laptop/dotfiles/misc/notification.wav
    transient: 1
```

`title` is required, everything else may be omitted. For the `data` parameters:

* `icon`: See `man notify-send`. Likely depends on your OS and distribution.
* `icon_file`: I have not tested this, but try passing an absolute path to an
  image on your target system and let me know what happens!
* `urgency`: 0 for `low` (default), 1 for `normal`, or 2 for `critical`.
* `sound`: I could not get the documented `sound-file` hint to work. Instead, if
  `aplay` is available, you can give an absolute path to a sound file on the
  target system and it will be played with the notification using `aplay`.
* `transient`: Set to 1 for a transient notification. See `man notify-send` for
  details.

## Contributing

Contributions are welcome. This is a very simple Elixir app with very few
dependencies. If you're running Nix, the flake includes a devshell that should
get you up and running immediately.

Improvements to the flake to support more ways of installing via Nix, and
packaging for other distributions, are of course welcome. I wrote this for me,
so packaging currently is what I needed both to run it on my own machine and to
see if I could learn to package an Elixir app in Nix (I could).

Other potential improvements include more robust support for icons and sounds.
Right now sound in particular is a bit of a hack. The source also includes a
*mostly* working `DBusNotifier` which speaks to DBus directly and therefore
would lose the dependency on `notify-send` (at least on Linux). Unfortunately, I
could not get the urgency hint to work, which I think may come down to the
Erlang `:dbus` library not quite marshalling hints properly. I would be
fascinated to learn how that might be fixed.
