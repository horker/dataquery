using System;
using System.Collections;
using System.Collections.Generic;
using System.Data.Common;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace Horker.Data.Classes
{
    internal static class Helpers
    {
        public static void SetParameters(DbCommand cmd, object parameters)
        {
            if (parameters == null)
                return;

            if (parameters is IDictionary dictParam)
            {
                foreach (DictionaryEntry entry in dictParam)
                {
                    object value;
                    if (entry.Value is PSObject psobj)
                        value = psobj.BaseObject;
                    else
                        value = entry.Value;

                    var param = cmd.CreateParameter();
                    param.ParameterName = (string)entry.Key;
                    param.Value = value;
                    cmd.Parameters.Add(param);
                }
            }
            else if (parameters is IEnumerable enumParam)
            {
                foreach (var v in enumParam)
                {
                    object value;
                    if (v is PSObject psobj)
                        value = psobj.BaseObject;
                    else
                        value = v;

                    var param = cmd.CreateParameter();
                    param.Value = value;
                    cmd.Parameters.Add(param);
                }
            }
            else
                throw new ArgumentException("Query parameters must be a IDictionary or an IEnumerable");
        }
    }
}
