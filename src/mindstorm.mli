(* File: mindstorm.mli

   Copyright (C) 2007-

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/anum/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 2.1 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)


(** Drive Lego Minsdstorm bricks with OCaml! *)

(** OCaml-mindstorm is a library that enables you to drive Lego
    mindstorm NXT or EV3 bricks from OCaml (the computer is the master
    and the brick is the slave). Communication with the brick is done
    through bluetooth (and possibly eventually USB).

    @author Christophe Troestler <Christophe.Troestler\@umons.ac.be>
*)

(** Interface to NXT bricks (it is an alias of {!module:Mindstorm_NXT}
    but [Mindstorm.NXT] should be used). *)
#if OCAML_MAJOR >= 4 && OCAML_MINOR >= 2
module NXT = Mindstorm_NXT
#else
module NXT : module type of Mindstorm_NXT
#endif

(** (ALPHA VERSION)
    Interface to EV3 bricks (it is an alias of {!module:Mindstorm_EV3}
    but [Mindstorm.EV3] should be used). *)
#if OCAML_MAJOR >= 4 && OCAML_MINOR >= 2
module EV3 = Mindstorm_EV3
#else
module EV3 : module type of Mindstorm_EV3
#endif



(************************************************************************)
(** {2:connectBluetooth How to connect the brick through bluetooth}

You need to create a serial port connection using the instructions
below for your platform.  Then use {!Minsdstorm.NXT.connect_bluetooth} to
create a handle for the brick.

{3 Linux}

First make sure your kernel has bluetooth support (this is likely) and
that the bluez and bluez-gnome (or kdebluetooth) pakages are
installed.  You should see a bluetooth applet icon.  Then do (the
text after the $ sign is what you type, underneath is the answer):

{v
        $ hcitool scan
        Scanning ...
                00:16:53:03:A5:32     NXT
v}

to discover the address of your brick.  Then use
{!Minsdstorm.NXT.connect_bluetooth}[ "00:16:53:03:A5:32"]
or {!Minsdstorm.EV3.connect_bluetooth}[ "00:16:53:03:A5:32"] to establish the
connection (of course, replace ["00:16:53:03:A5:32"] by your actual
bluetooth address) — the first time, the brick will ask you to enter
a code and the bluetooth applet will pop up a box in which you need to
copy the very same code (this is to forbid unwanted connections).

If test programs fail with [Unix.Unix_error(Unix.EUNKNOWNERR ...)]
and your computer does not ask you the passkey (which may indicate
that you should check that the blueman applet is not running multiple
times), pair the brick with your computer first.  One way to do it is
to run [bluetoothctl] and type at its prompt (output only partly
shown):

{v
        [bluetooth]# scan on
        Discovery started
        [CHG] Controller 87:EE:A8:C3:A5:83 Discovering: yes
        [NEW] Device 01:15:34:56:31:11 EV3
        [bluetooth]# agent on
        Agent registered
        [bluetooth]# default-agent
        Default agent request successful
        [bluetooth]# pair 01:15:34:56:31:11
        Attempting to pair with 01:15:34:56:31:11
        Request PIN code
        [agent] Enter PIN code: 1234
        ...
v}

You should then be able to connect to the brick without confirmation
being requested.


{3 MacOS X}

We follow here the instructions
"{{:http://tonybuser.com/bluetooth-serial-port-to-nxt-in-osx}Bluetooth
Serial Port To NXT in OSX}":
{ol
{- Turn on the NXT brick and make sure bluetooth is on (you should
   see a bluetooth icon at the top left corner);}
{- Click the bluetooth icon in the menubar, select "Setup bluetooth device";}
{- When it asks for Select Device Type, choose "Any device";}
{- Select [NXT] (or whatever your brick is called but [NXT] is the factory
    setting so we'll use that from now on) from the list and click continue;}
{- The NXT will beep and ask for a passkey, choose 1234 (the default but
   you can choose anything you like) and press the orange button;}
{- Click continue in OSX, enter same passkey as above (1234 by default);}
{- The NXT will beep again, press orange button to use 1234 again;}
{- The mac will complain "There were no supported services found on your
   device"; don't worry about that and click continue and then click Quit;}
{- In OSX click the bluetooth icon, select "Open bluetooth
   preferences", you should see [NXT] (or whatever your brick is
   called) listed, select it, then click "Edit Serial Ports";}
{- It should show [NXT-DevB-1] (replace [NXT] by the name of your
   brick), if not click add, use Port Name: [NXT-DevB-1], Device
   Service: Dev B, Port type: RS-232.  Click Apply.}}

You're done! You should now have a [/dev/tty.NXT-DevB-1].

Now you can connect to the brick using {!Minsdstorm.NXT.connect_bluetooth}[
"/dev/tty.NXT-DevB-1"].  Beware that if you rename the brick with
{!Mindstorm.set_brick_name}, you will have to change the TTY device
accordingly.


{3 Windows}

{4 Without the fantom drivers installed}

From windows, open the bluetooth control panel, create a new
connection to the NXT brick, right click on your connection and select
"details" to see which serial port is used, for example COM40.  Then
use {!Mindstorm.NXT.connect_bluetooth}[ "COM40"] to connect to the brick from
your programs.  ATM, you have to always start by establishing the
connection by hand before you can use the brick.  Patches are welcome
so that is is enough to pass the bluetooth address to
{!Mindstorm.NXT.connect_bluetooth} and the library performs the
connection.

Windows Vista uses different ports for outgoing and incoming
connections (e.g. COM4 for outgoing connections and COM5 for incoming
ones).  With this library, you must use the outgoing port.

See also
{{:http://juju.org/articles/2006/08/16/ruby-serialport-nxt-on-windows}ruby-serialport/nxt
on Windows} with Cygwin.

{4 With the fantom drivers installed}

Once the fantom drivers are on your machine (which is the case if you
installed the LEGO® NXTG software), the above method does not work
anymore.  It is then probably necessary to use these drivers through
the {{:http://mindstorms.lego.com/Overview/NXTreme.aspx}Driver SDK}.
This will be investigated in a subsequent revision of this library.



{2:connectUSB How to connect the brick through USB}

{3 Linux}

For easy access, create a [lego] group, add your user to it, and create
a file [/etc/udev/rules.d/70-lego.rules] containing:
{v
        # Lego NXT                                               -*-conf-*-
        BUS=="usb", SYSFS{idVendor}=="0694", GROUP="lego", MODE="0660"
v}

To list the NXT bricks connected through USB to your computer, use
{!Mindstorm.USB.bricks}. To connect to one of these bricks, say [b],
use {!Mindstorm.USB.connect}[ b] (you can the query the brick, say for
its name, to decide whether it is the device you want to talk to).

{3 MacOS X}

TBD.

{3 Windows}

Install {{:http://libusb-win32.sourceforge.net/}libusb-win32}.

you need the LEGO® Mindstorms NXT software installed, as its USB
drivers are used. ???
 *)
;;
