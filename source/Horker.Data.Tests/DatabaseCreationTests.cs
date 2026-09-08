using System;
using System.IO;
using Xunit;

namespace Horker.Data.Tests
{
    public class DatabaseCreationTests
    {
        [Theory]
        [InlineData(false)]
        [InlineData(true)]
        public void InitializationFailurePreservesDestinationAndCleansTemporaryFiles(bool exists)
        {
            var directory = Path.Combine(Path.GetTempPath(), "Horker-create-test-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(directory);
            var path = Path.Combine(directory, "data.db");
            try
            {
                if (exists) File.WriteAllText(path, "original");
                var failure = new InvalidOperationException("Initialization failure");
                Assert.Same(failure, Assert.Throws<InvalidOperationException>(() => DatabaseCreation.Create(path, true, temporary =>
                {
                    File.WriteAllText(temporary, "partial");
                    File.WriteAllText(temporary + "-journal", "partial");
                    throw failure;
                })));
                Assert.Empty(Directory.GetDirectories(directory));
                if (exists) Assert.Equal("original", File.ReadAllText(path));
                else Assert.False(File.Exists(path));
            }
            finally { File.Delete(path); Directory.Delete(directory); }
        }

        [Fact]
        public void NewDestinationAppearingDuringInitializationIsNotOverwritten()
        {
            var directory = Path.Combine(Path.GetTempPath(), "Horker-create-test-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(directory);
            var path = Path.Combine(directory, "data.db");
            try
            {
                Assert.Throws<IOException>(() => DatabaseCreation.Create(path, false, temporary =>
                {
                    File.WriteAllText(temporary, "new");
                    File.WriteAllText(path, "other process");
                }));
                Assert.Equal("other process", File.ReadAllText(path));
                Assert.Empty(Directory.GetDirectories(directory));
            }
            finally { File.Delete(path); Directory.Delete(directory); }
        }
    }
}
