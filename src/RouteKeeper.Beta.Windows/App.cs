using System.Windows;
using System.Windows.Controls;

namespace RouteKeeper.Beta.Windows;

public sealed class App : Application
{
    [STAThread]
    public static int Main(string[] args)
    {
        var app = new App();
        var button = new Style(typeof(Button));
        button.Setters.Add(new Setter(Control.PaddingProperty, new Thickness(12, 8, 12, 8)));
        button.Setters.Add(new Setter(FrameworkElement.MarginProperty, new Thickness(4)));
        app.Resources[typeof(Button)] = button;
        app.DispatcherUnhandledException += (_, e) =>
        {
            MessageBox.Show("The operation failed. Previously committed results are retained.\n작업에 실패했습니다. 저장된 결과는 유지됩니다.\n" + e.Exception.Message, "ROUTEKEEPER", MessageBoxButton.OK, MessageBoxImage.Error);
            e.Handled = true;
        };
        // CI verifies only construction/data binding on a real Windows STA thread.
        // It does not claim interactive rendering or launch Steam/the game.
        if (args is ["--smoke-test"] or ["--smoke-package"])
        {
            if (args[0] == "--smoke-package") NativeController.SmokePackage();
            var window = new MainWindow();
            window.Show(); window.UpdateLayout(); window.SmokeTest(); window.Close();
            return 0;
        }
        return app.Run(new MainWindow());
    }
}
