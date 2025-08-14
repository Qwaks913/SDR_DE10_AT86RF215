#!/usr/bin/env python3
"""
Simple UDP daemon to receive register configuration, write to config.txt,
and (re)launch the example_spi_dma executable.
"""
import socket
import subprocess
import os
import signal
import sys

# Settings
dumask_old = os.umask(0)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UDP_PORT = 6000
CONFIG_FILE = os.path.join(BASE_DIR, "config.txt")
EXECUTABLE = os.path.join(BASE_DIR, "example_spi_dma")
SIMPLE_LAUNCH_SCRIPT = os.path.join(BASE_DIR, "simple_launch.sh")
# Listening on all interfaces
UDP_ADDR = ('', UDP_PORT)

# Current child process
child_proc = None

def handle_shutdown(signo, _frame):
    """Clean up child on exit."""
    global child_proc
    if child_proc and child_proc.poll() is None:
        child_proc.terminate()
    sys.exit(0)


def restart_executable():
    """Kill previous process if needed and start a new one."""
    global child_proc
    if child_proc and child_proc.poll() is None:
        child_proc.terminate()
        child_proc.wait()
    
    # Utiliser le script simple_launch.sh qui fonctionne correctement
    if os.path.exists(SIMPLE_LAUNCH_SCRIPT):
        cmd = [SIMPLE_LAUNCH_SCRIPT]
        print(f"Using simple launch script: {SIMPLE_LAUNCH_SCRIPT}")
    else:
        # Fallback direct si le script n'existe pas
        cmd = [EXECUTABLE, 'udp']
        print(f"Script not found, using direct launch: {EXECUTABLE}")
    
    try:
        child_proc = subprocess.Popen(cmd, cwd=BASE_DIR)
        print(f"Launched PID {child_proc.pid}")
    except Exception as e:
        print(f"Error launching process: {e}")
        return


def main():
    # Setup signal handlers
    signal.signal(signal.SIGINT, handle_shutdown)
    signal.signal(signal.SIGTERM, handle_shutdown)

    # Create UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(UDP_ADDR)
    print(f"Config daemon listening on UDP port {UDP_PORT}...")

    while True:
        data, addr = sock.recvfrom(8192)
        text = data.decode('utf-8').strip()
        # If a stop command is received, terminate child and continue loop
        if text.upper() == 'STOP':
            if child_proc and child_proc.poll() is None:
                child_proc.terminate()
                child_proc.wait()
            continue
        # Otherwise treat as config update
        try:
            with open(CONFIG_FILE, 'w') as f:
                f.write('# Update from config_daemon\n')
                f.write(text)
        except Exception as e:
            # ignore write errors
            continue
        # Restart the streaming executable
        restart_executable()

if __name__ == '__main__':
    main()
