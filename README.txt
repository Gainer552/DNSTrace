DNSTrace - DNS Configuration Drift Tracker for Linux


Overview
DNSTrace is a lightweight, Bash-based DNS configuration drift detection tool for Linux systems. It helps security professionals, system administrators, and privacy-conscious users detect unauthorized or unexpected changes to local DNS configurations. This is particularly useful for identifying:

- Host file poisoning (e.g. internal IPs mapped to real domains).
- DNS resolver hijacking.
- Systemd-resolved setting downgrades (DNSSEC, LLMNR, DoT, etc.)
- VPN or interface-based DNS injection.
- Suspicious resolver overrides via NetworkManager.

How it Works
DNSTrace works in two modes:

1. Create DNS Configuration Baseline
   - Gathers local DNS-related configuration data from /etc/resolv.conf, /etc/nsswitch.conf, systemd-resolve, nmcli, /etc/hosts, and active interfaces.
   - Saves the results to a timestamped .txt file with immutable attributes (chattr +i).

2. Compare Two Baselines
   - Accepts two baseline .txt files as input.
   - Highlights configuration drift in a color-coded, sectioned format.
   - Flags host file changes, DNSSEC offloading, new interfaces, and more.

Example Use Cases
- Confirm DNS behavior after connecting to untrusted Wi-Fi.
- Detect tampering during red team engagements.
- Validate VPN kill-switch / DNS leak resistance.
- Monitor for changes post-incident or post-patch.

Usage
1. Run the script: sudo ./dnstrace.sh

2. Choose from:
    - Option 1: Create a DNS baseline snapshot.
    - Option 2: Compare a prior baseline against a new one.

Dependencies
- bash
- dnsutils *(Install with sudo pacman -S dnsutils on Arch/Manjaro)*
- iproute2, coreutils, nmcli, systemd-resolve or resolvectl

Baseline File Behavior
- Stored in the current directory as dns-baseline-YYYYMMDD-HHMMSS.txt.
- Owned by the invoking user.
- Automatically marked immutable with chattr +i to prevent tampering

Security Tips
- Keep baselines locked to detect tampering (lsattr to verify).
- Schedule periodic snapshots and comparisons via cron or systemd.
- Review .hosts changes for suspicious internal mappings to public domains.

Disclaimer
This tool is provided "as-is" without warranty of any kind, express or implied. Usage of DNSTrace is at your own risk. It is intended for legitimate security monitoring, system integrity assurance, and educational purposes only. Unauthorized monitoring or tampering of systems you do not own or have explicit permission to test may be illegal in your jurisdiction.

Author assumes no responsibility for misuse of this script.
