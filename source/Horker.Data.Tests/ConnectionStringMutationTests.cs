using System;
using System.Configuration;
using Xunit;

namespace Horker.Data.Tests
{
    public class ConnectionStringMutationTests
    {
        [Fact]
        public void RestoresReadOnlyStateWhenMutationThrows()
        {
            var collection = ConfigurationManager.ConnectionStrings;
            bool readOnly = collection.IsReadOnly();
            Assert.Throws<InvalidOperationException>(() => ConnectionStringMutation.Apply(c =>
            {
                Assert.False(c.IsReadOnly());
                throw new InvalidOperationException("Test failure");
            }));
            Assert.Equal(readOnly, collection.IsReadOnly());
        }
    }
}
