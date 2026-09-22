using System;
using System.Drawing;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Forms;
using System.Windows.Interop;
using System.Windows.Media.Imaging;
using Application = System.Windows.Application;

namespace QuickSnag
{
    public partial class App : Application
    {
        private NotifyIcon? _notifyIcon;
        private MainWindow? _mainWindow;
        private HwndSource? _hwndSource;
        private bool _autoOpenOnClipboard = true;

        private const int HOTKEY_ID = 9000;
        private const uint MOD_CONTROL = 0x0002;
        private const uint MOD_SHIFT = 0x0004;
        private const uint VK_S = 0x53;
        private const int WM_HOTKEY = 0x0312;
        private const int WM_CLIPBOARDUPDATE = 0x031D;

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        [DllImport("user32.dll")]
        private static extern bool AddClipboardFormatListener(IntPtr hwnd);

        [DllImport("user32.dll")]
        private static extern bool RemoveClipboardFormatListener(IntPtr hwnd);

        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);

            _mainWindow = new MainWindow();

            // Hidden dummy window message pump for hotkeys and clipboard
            var parameters = new HwndSourceParameters("QuickSnagListener")
            {
                WindowStyle = 0,
                Width = 0,
                Height = 0,
            };
            _hwndSource = new HwndSource(parameters);
            _hwndSource.AddHook(HwndHook);

            RegisterHotKey(_hwndSource.Handle, HOTKEY_ID, MOD_CONTROL | MOD_SHIFT, VK_S);
            AddClipboardFormatListener(_hwndSource.Handle);

            SetupTray();
        }

        private void SetupTray()
        {
            _notifyIcon = new NotifyIcon
            {
                Text = "QuickSnag - Screen Capture & Annotator",
                Icon = SystemIcons.Application,
                Visible = true
            };

            var menu = new ContextMenuStrip();
            menu.Items.Add("QuickSnag v1.0 (Windows Native)", null, (s, e) => { }).Enabled = false;
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Capture Screen Area (Ctrl+Shift+S)", null, (s, e) => TriggerCapture());
            menu.Items.Add("Open from Clipboard (Ctrl+V)", null, (s, e) => OpenClipboard());
            menu.Items.Add(new ToolStripSeparator());

            var autoOpenItem = new ToolStripMenuItem("Auto-open on OS Screenshot") { Checked = _autoOpenOnClipboard };
            autoOpenItem.Click += (s, e) =>
            {
                _autoOpenOnClipboard = !_autoOpenOnClipboard;
                autoOpenItem.Checked = _autoOpenOnClipboard;
            };
            menu.Items.Add(autoOpenItem);

            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Exit QuickSnag", null, (s, e) => Shutdown());

            _notifyIcon.ContextMenuStrip = menu;
            _notifyIcon.MouseClick += (s, e) =>
            {
                if (e.Button == MouseButtons.Left)
                {
                    TriggerCapture();
                }
            };
            _notifyIcon.DoubleClick += (s, e) => TriggerCapture();
        }

        public void TriggerCapture()
        {
            Dispatcher.Invoke(() =>
            {
                _mainWindow?.Hide();
                var bounds = Screen.PrimaryScreen?.Bounds ?? new Rectangle(0, 0, 1920, 1080);
                using var bmp = new Bitmap(bounds.Width, bounds.Height);
                using (var g = Graphics.FromImage(bmp))
                {
                    g.CopyFromScreen(bounds.X, bounds.Y, 0, 0, bounds.Size);
                }

                var bitmapImage = ConvertToBitmapImage(bmp);
                _mainWindow?.LoadImage(bitmapImage);
                _mainWindow?.Show();
                _mainWindow?.Activate();
            });
        }

        public void OpenClipboard()
        {
            Dispatcher.Invoke(() =>
            {
                if (System.Windows.Clipboard.ContainsImage())
                {
                    var img = System.Windows.Clipboard.GetImage();
                    if (img != null)
                    {
                        _mainWindow?.LoadImage(img);
                        _mainWindow?.Show();
                        _mainWindow?.Activate();
                    }
                }
            });
        }

        private IntPtr HwndHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (msg == WM_HOTKEY && wParam.ToInt32() == HOTKEY_ID)
            {
                TriggerCapture();
                handled = true;
            }
            else if (msg == WM_CLIPBOARDUPDATE && _autoOpenOnClipboard)
            {
                if (System.Windows.Clipboard.ContainsImage())
                {
                    var img = System.Windows.Clipboard.GetImage();
                    if (img != null && img.PixelWidth > 50 && img.PixelHeight > 50)
                    {
                        _mainWindow?.LoadImage(img);
                        _mainWindow?.Show();
                        _mainWindow?.Activate();
                    }
                }
            }
            return IntPtr.Zero;
        }

        private static BitmapImage ConvertToBitmapImage(Bitmap src)
        {
            using var ms = new MemoryStream();
            src.Save(ms, System.Drawing.Imaging.ImageFormat.Png);
            ms.Position = 0;
            var bi = new BitmapImage();
            bi.BeginInit();
            bi.CacheOption = BitmapCacheOption.OnLoad;
            bi.StreamSource = ms;
            bi.EndInit();
            bi.Freeze();
            return bi;
        }

        protected override void OnExit(ExitEventArgs e)
        {
            if (_hwndSource != null)
            {
                UnregisterHotKey(_hwndSource.Handle, HOTKEY_ID);
                RemoveClipboardFormatListener(_hwndSource.Handle);
                _hwndSource.Dispose();
            }

            if (_notifyIcon != null)
            {
                _notifyIcon.Visible = false;
                _notifyIcon.Dispose();
            }

            base.OnExit(e);
        }
    }
}
