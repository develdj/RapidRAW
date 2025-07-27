# RapidRAW Remote Desktop Setup

This setup creates a complete remote desktop environment in Docker, allowing you to access RapidRAW as if it were running on a remote computer.

## Features

- **Full Desktop Environment**: Complete XFCE desktop, not just the application
- **Web Browser Access**: Access via any modern web browser at `http://your-server:6080`
- **VNC Client Access**: Connect with any VNC client to port 5901
- **Auto-start RapidRAW**: The application launches automatically when you connect
- **Persistent Settings**: Desktop customizations are saved between restarts
- **GPU Acceleration**: Supports NVIDIA GPU on Jetson Orin

## Quick Start

1. **Build and Deploy**:
   ```bash
   # Build the remote desktop image
   docker-compose -f docker-compose.remote.yml build
   
   # Start the remote desktop
   docker-compose -f docker-compose.remote.yml up -d
   ```

2. **Access the Desktop**:
   - **Web Browser** (Recommended): 
     - Open `http://your-server-ip:6080/vnc.html`
     - Click "Connect"
     - No password needed for web access
   
   - **VNC Client** (Advanced):
     - Server: `your-server-ip:5901`
     - Password: `rapidraw` (can be changed in Dockerfile)

3. **Using RapidRAW**:
   - RapidRAW starts automatically when you connect
   - You can also find it on the desktop or in the applications menu
   - The full desktop allows you to manage files, use terminal, etc.

## Customization

### Change Resolution
Edit `docker-compose.remote.yml`:
```yaml
environment:
  - VNC_RESOLUTION=2560x1440  # Or any resolution you prefer
```

### Change VNC Password
In `Dockerfile.remote-desktop`, modify:
```bash
echo "your-new-password" | vncpasswd -f > /root/.vnc/passwd
```

### Disable Auto-start
Remove the RapidRAW launch line from `/root/.vnc/xstartup` in the Dockerfile.

## Performance Tips

1. **For Best Performance**:
   - Use a wired network connection
   - Adjust the color depth if needed: `VNC_COL_DEPTH=16`
   - Limit resolution on slower connections

2. **GPU Acceleration**:
   - Already enabled for Jetson Orin
   - Ensures smooth graphics performance

## Troubleshooting

- **Black Screen**: Wait 30-60 seconds for desktop to fully load
- **Cannot Connect**: Check firewall rules for ports 6080 and 5901
- **Performance Issues**: Reduce resolution or color depth

## Security Notes

- Change the default VNC password for production use
- Consider using a reverse proxy with HTTPS for web access
- Limit port exposure using firewall rules
