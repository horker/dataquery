using System;
using System.Management.Automation;

namespace Horker.Data
{
    internal static class DatabasePath
    {
        internal static string Resolve(string path, SessionState sessionState)
        {
            ProviderInfo provider;
            PSDriveInfo drive;
            var resolved = sessionState.Path.GetUnresolvedProviderPathFromPSPath(path, out provider, out drive);
            if (provider.Name != "FileSystem") throw new ArgumentException("Path must use the FileSystem provider.");
            return resolved;
        }
    }
}
