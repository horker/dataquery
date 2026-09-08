using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Management.Automation;
using System.Management.Automation.Host;
using System.Security;

public sealed class DataQueryDecliningHost : PSHost
{
    private readonly PSHost inner;
    private readonly DecliningUI ui;
    public DataQueryDecliningHost(PSHost inner) { this.inner = inner; ui = new DecliningUI(inner.UI); }
    public int Prompts { get { return ui.Prompts; } }
    public override Guid InstanceId { get { return inner.InstanceId; } }
    public override string Name { get { return "DataQueryDecliningHost"; } }
    public override Version Version { get { return inner.Version; } }
    public override CultureInfo CurrentCulture { get { return inner.CurrentCulture; } }
    public override CultureInfo CurrentUICulture { get { return inner.CurrentUICulture; } }
    public override PSHostUserInterface UI { get { return ui; } }
    public override void EnterNestedPrompt() { throw new NotSupportedException(); }
    public override void ExitNestedPrompt() { throw new NotSupportedException(); }
    public override void NotifyBeginApplication() { }
    public override void NotifyEndApplication() { }
    public override void SetShouldExit(int exitCode) { }

    private sealed class DecliningUI : PSHostUserInterface
    {
        private readonly PSHostUserInterface inner;
        public int Prompts;
        public DecliningUI(PSHostUserInterface inner) { this.inner = inner; }
        public override PSHostRawUserInterface RawUI { get { return inner.RawUI; } }
        public override int PromptForChoice(string caption, string message, Collection<ChoiceDescription> choices, int defaultChoice)
        {
            Prompts++;
            for (int i = 0; i < choices.Count; i++)
                if (choices[i].Label.Replace("&", "") == "No") return i;
            throw new InvalidOperationException("Expected a No confirmation choice.");
        }
        public override Dictionary<string, PSObject> Prompt(string caption, string message, Collection<FieldDescription> descriptions) { throw new NotSupportedException(); }
        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName) { throw new NotSupportedException(); }
        public override PSCredential PromptForCredential(string caption, string message, string userName, string targetName, PSCredentialTypes types, PSCredentialUIOptions options) { throw new NotSupportedException(); }
        public override string ReadLine() { throw new NotSupportedException(); }
        public override SecureString ReadLineAsSecureString() { throw new NotSupportedException(); }
        public override void Write(string value) { }
        public override void Write(ConsoleColor foregroundColor, ConsoleColor backgroundColor, string value) { }
        public override void WriteLine(string value) { }
        public override void WriteErrorLine(string value) { }
        public override void WriteDebugLine(string message) { }
        public override void WriteProgress(long sourceId, ProgressRecord record) { }
        public override void WriteVerboseLine(string message) { }
        public override void WriteWarningLine(string message) { }
    }
}
