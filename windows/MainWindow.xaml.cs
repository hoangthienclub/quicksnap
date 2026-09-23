using System;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using Microsoft.Win32;

namespace QuickSnag
{
    public partial class MainWindow : Window
    {
        private string _currentTool = "Arrow";
        private SolidColorBrush _currentColor = new SolidColorBrush((Color)ColorConverter.ConvertFromString("#EF4444"));
        private int _stepCount = 1;
        private Point _startPoint;
        private Shape? _activeShape;
        private BitmapSource? _baseImage;
        private UIElement? _selectedElement;
        private Point _lastDragPoint;
        private bool _isDraggingElement;
        private bool _isResizingElement;

        public MainWindow()
        {
            InitializeComponent();
        }

        public void LoadImage(BitmapSource img)
        {
            _baseImage = img;
            BaseImageDisplay.Source = img;
            DrawingCanvas.Width = img.PixelWidth;
            DrawingCanvas.Height = img.PixelHeight;
            DrawingCanvas.Children.Clear();
            _stepCount = 1;
            StepBtn.Content = "① 1";
        }

        private void Tool_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button btn && btn.Tag is string tool)
            {
                _currentTool = tool;
            }
        }

        private void Color_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button btn && btn.Tag is string hex)
            {
                _currentColor = new SolidColorBrush((Color)ColorConverter.ConvertFromString(hex));
            }
        }

        private void DrawingCanvas_MouseDown(object sender, MouseButtonEventArgs e)
        {
            _startPoint = e.GetPosition(DrawingCanvas);

            if (_selectedElement != null)
            {
                if (_selectedElement is Line line)
                {
                    if (Math.Sqrt(Math.Pow(_startPoint.X - line.X2, 2) + Math.Pow(_startPoint.Y - line.Y2, 2)) <= 18)
                    {
                        _isResizingElement = true;
                        _lastDragPoint = _startPoint;
                        return;
                    }
                }
                else if (_selectedElement is FrameworkElement fe)
                {
                    double left = Canvas.GetLeft(fe);
                    double top = Canvas.GetTop(fe);
                    if (double.IsNaN(left)) left = 0;
                    if (double.IsNaN(top)) top = 0;
                    double right = left + (double.IsNaN(fe.Width) ? fe.ActualWidth : fe.Width);
                    double bottom = top + (double.IsNaN(fe.Height) ? fe.ActualHeight : fe.Height);

                    if (Math.Abs(_startPoint.X - right) <= 18 && Math.Abs(_startPoint.Y - bottom) <= 18)
                    {
                        _isResizingElement = true;
                        _lastDragPoint = _startPoint;
                        return;
                    }
                }
            }

            if (_currentTool == "Select" || Keyboard.IsKeyDown(Key.LeftCtrl) || Keyboard.IsKeyDown(Key.RightCtrl))
            {
                var hit = DrawingCanvas.InputHitTest(_startPoint) as UIElement;
                if (hit != null && hit != DrawingCanvas && hit != BaseImageDisplay)
                {
                    var elem = hit;
                    while (elem != null && VisualTreeHelper.GetParent(elem) != DrawingCanvas)
                    {
                        elem = VisualTreeHelper.GetParent(elem) as UIElement;
                    }
                    if (elem != null)
                    {
                        _selectedElement = elem;
                        _isDraggingElement = true;
                        _lastDragPoint = _startPoint;
                        return;
                    }
                }
                _selectedElement = null;
                return;
            }

            if (_currentTool == "Step")
            {
                AddStepBadge(_startPoint, _stepCount++);
                StepBtn.Content = $"① {_stepCount}";
                return;
            }

            if (_currentTool == "Text")
            {
                AddInlineTextBox(_startPoint);
                return;
            }

            switch (_currentTool)
            {
                case "Arrow":
                    var line = new Line
                    {
                        Stroke = _currentColor,
                        StrokeThickness = 4,
                        X1 = _startPoint.X,
                        Y1 = _startPoint.Y,
                        X2 = _startPoint.X,
                        Y2 = _startPoint.Y,
                        StrokeEndLineCap = PenLineCap.Round
                    };
                    _activeShape = line;
                    DrawingCanvas.Children.Add(line);
                    break;

                case "Rect":
                    var rect = new Rectangle
                    {
                        Stroke = _currentColor,
                        StrokeThickness = 4,
                        RadiusX = 6,
                        RadiusY = 6
                    };
                    Canvas.SetLeft(rect, _startPoint.X);
                    Canvas.SetTop(rect, _startPoint.Y);
                    _activeShape = rect;
                    DrawingCanvas.Children.Add(rect);
                    break;

                case "Circle":
                    var oval = new Ellipse
                    {
                        Stroke = _currentColor,
                        StrokeThickness = 4
                    };
                    Canvas.SetLeft(oval, _startPoint.X);
                    Canvas.SetTop(oval, _startPoint.Y);
                    _activeShape = oval;
                    DrawingCanvas.Children.Add(oval);
                    break;
            }
        }

        private void DrawingCanvas_MouseMove(object sender, MouseEventArgs e)
        {
            if (e.LeftButton != MouseButtonState.Pressed) return;
            var cur = e.GetPosition(DrawingCanvas);

            if (_isResizingElement && _selectedElement != null)
            {
                if (_selectedElement is Line line)
                {
                    line.X2 = cur.X;
                    line.Y2 = cur.Y;
                }
                else if (_selectedElement is FrameworkElement fe)
                {
                    double left = Canvas.GetLeft(fe);
                    double top = Canvas.GetTop(fe);
                    if (double.IsNaN(left)) left = 0;
                    if (double.IsNaN(top)) top = 0;
                    fe.Width = Math.Max(10, cur.X - left);
                    fe.Height = Math.Max(10, cur.Y - top);
                }
                _lastDragPoint = cur;
                return;
            }

            if (_isDraggingElement && _selectedElement != null)
            {
                double dx = cur.X - _lastDragPoint.X;
                double dy = cur.Y - _lastDragPoint.Y;

                if (_selectedElement is Line line)
                {
                    line.X1 += dx; line.X2 += dx;
                    line.Y1 += dy; line.Y2 += dy;
                }
                else
                {
                    double left = Canvas.GetLeft(_selectedElement);
                    double top = Canvas.GetTop(_selectedElement);
                    if (double.IsNaN(left)) left = 0;
                    if (double.IsNaN(top)) top = 0;
                    Canvas.SetLeft(_selectedElement, left + dx);
                    Canvas.SetTop(_selectedElement, top + dy);
                }
                _lastDragPoint = cur;
                return;
            }

            if (_activeShape == null) return;

            if (_activeShape is Line l)
            {
                l.X2 = cur.X;
                l.Y2 = cur.Y;
            }
            else if (_activeShape is Rectangle r)
            {
                var x = Math.Min(_startPoint.X, cur.X);
                var y = Math.Min(_startPoint.Y, cur.Y);
                Canvas.SetLeft(r, x);
                Canvas.SetTop(r, y);
                r.Width = Math.Abs(cur.X - _startPoint.X);
                r.Height = Math.Abs(cur.Y - _startPoint.Y);
            }
            else if (_activeShape is Ellipse el)
            {
                var x = Math.Min(_startPoint.X, cur.X);
                var y = Math.Min(_startPoint.Y, cur.Y);
                Canvas.SetLeft(el, x);
                Canvas.SetTop(el, y);
                el.Width = Math.Abs(cur.X - _startPoint.X);
                el.Height = Math.Abs(cur.Y - _startPoint.Y);
            }
        }

        private void DrawingCanvas_MouseUp(object sender, MouseButtonEventArgs e)
        {
            _activeShape = null;
            _isDraggingElement = false;
            _isResizingElement = false;
        }

        private void AddStepBadge(Point p, int num)
        {
            var badge = new Grid { Width = 32, Height = 32 };
            var el = new Ellipse
            {
                Fill = _currentColor,
                Stroke = Brushes.White,
                StrokeThickness = 2.5
            };
            var tb = new TextBlock
            {
                Text = num.ToString(),
                Foreground = Brushes.White,
                FontWeight = FontWeights.Bold,
                FontSize = 14,
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
            badge.Children.Add(el);
            badge.Children.Add(tb);
            Canvas.SetLeft(badge, p.X - 16);
            Canvas.SetTop(badge, p.Y - 16);
            DrawingCanvas.Children.Add(badge);
        }

        private void AddInlineTextBox(Point p)
        {
            var tb = new TextBox
            {
                Background = Brushes.Transparent,
                Foreground = _currentColor,
                FontSize = 20,
                FontWeight = FontWeights.Bold,
                BorderBrush = _currentColor,
                BorderThickness = new Thickness(1),
                MinWidth = 120,
                CaretBrush = _currentColor
            };

            tb.KeyDown += (s, e) =>
            {
                if (e.Key == Key.Enter)
                {
                    tb.BorderThickness = new Thickness(0);
                    tb.IsReadOnly = true;
                }
            };

            Canvas.SetLeft(tb, p.X);
            Canvas.SetTop(tb, p.Y);
            DrawingCanvas.Children.Add(tb);
            tb.Focus();
        }

        private void Undo_Click(object sender, RoutedEventArgs e)
        {
            if (DrawingCanvas.Children.Count > 0)
            {
                DrawingCanvas.Children.RemoveAt(DrawingCanvas.Children.Count - 1);
            }
        }

        private RenderTargetBitmap RenderCanvas()
        {
            var w = (int)DrawingCanvas.Width;
            var h = (int)DrawingCanvas.Height;
            var rtb = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32);
            rtb.Render(CanvasContainer);
            return rtb;
        }

        private void Copy_Click(object sender, RoutedEventArgs e)
        {
            var rtb = RenderCanvas();
            System.Windows.Clipboard.SetImage(rtb);
            Hide();
        }

        private void Save_Click(object sender, RoutedEventArgs e)
        {
            var sfd = new SaveFileDialog
            {
                Filter = "PNG Image (*.png)|*.png|JPEG Image (*.jpg)|*.jpg",
                FileName = $"QuickSnag_{DateTime.Now:yyyyMMdd_HHmmss}.png"
            };

            if (sfd.ShowDialog() == true)
            {
                var rtb = RenderCanvas();
                var encoder = new PngBitmapEncoder();
                encoder.Frames.Add(BitmapFrame.Create(rtb));
                using var fs = File.OpenWrite(sfd.FileName);
                encoder.Save(fs);
            }
        }

        private void Close_Click(object sender, RoutedEventArgs e)
        {
            Hide();
        }

        private void Window_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Escape)
            {
                Hide();
            }
            else if (e.Key == Key.Enter || (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.C))
            {
                Copy_Click(this, new RoutedEventArgs());
            }
            else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.S)
            {
                Save_Click(this, new RoutedEventArgs());
            }
            else if (Keyboard.Modifiers == ModifierKeys.Control && e.Key == Key.Z)
            {
                Undo_Click(this, new RoutedEventArgs());
            }
            else if (e.Key == Key.Delete || e.Key == Key.Back)
            {
                if (_selectedElement != null)
                {
                    DrawingCanvas.Children.Remove(_selectedElement);
                    _selectedElement = null;
                }
            }
            else if (e.Key == Key.V)
            {
                _currentTool = "Select";
            }
        }
    }
}
