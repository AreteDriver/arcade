using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Combat;
using YokaiBlade.Core.Telegraphs;

namespace YokaiBlade.Tests.EditMode
{
    public class AttackDataTests
    {
        [Test]
        public void AttackDefinition_ValidAttack_Passes()
        {
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            attack.AttackId = "TestAttack";
            attack.StartupFrames = 10;
            attack.ActiveFrames = 5;
            attack.RecoveryFrames = 15;
            attack.HitboxSize = Vector3.one;

            Assert.That(attack.Validate(out _), Is.True);
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackDefinition_EmptyId_Fails()
        {
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            attack.AttackId = "";

            Assert.That(attack.Validate(out var error), Is.False);
            Assert.That(error, Does.Contain("AttackId"));
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackDefinition_TelegraphLeadExceedsStartup_Fails()
        {
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            attack.AttackId = "Test";
            attack.StartupFrames = 5;
            attack.TelegraphLeadFrames = 10;

            Assert.That(attack.Validate(out var error), Is.False);
            Assert.That(error, Does.Contain("TelegraphLeadFrames"));
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackDefinition_UnblockableWithDeflect_Fails()
        {
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            attack.AttackId = "Test";
            attack.Unblockable = true;
            attack.CorrectResponse = AttackResponse.Deflect;

            Assert.That(attack.Validate(out var error), Is.False);
            Assert.That(error, Does.Contain("Unblockable"));
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackDefinition_TimingComputed_At60fps()
        {
            var attack = ScriptableObject.CreateInstance<AttackDefinition>();
            attack.AttackId = "Test";
            attack.StartupFrames = 60;
            attack.ActiveFrames = 30;
            attack.RecoveryFrames = 30;

            Assert.That(attack.StartupDuration, Is.EqualTo(1f).Within(0.001f));
            Assert.That(attack.ActiveDuration, Is.EqualTo(0.5f).Within(0.001f));
            Assert.That(attack.TotalDuration, Is.EqualTo(2f).Within(0.001f));
            Object.DestroyImmediate(attack);
        }

        [Test]
        public void AttackValidator_DuplicateIds_Fails()
        {
            var a1 = ScriptableObject.CreateInstance<AttackDefinition>();
            a1.AttackId = "Same";
            a1.HitboxSize = Vector3.one;
            var a2 = ScriptableObject.CreateInstance<AttackDefinition>();
            a2.AttackId = "Same";
            a2.HitboxSize = Vector3.one;

            var valid = AttackValidator.ValidateAll(new[] { a1, a2 }, out var errors);

            Assert.That(valid, Is.False);
            Assert.That(errors, Has.Some.Contain("Duplicate"));

            Object.DestroyImmediate(a1);
            Object.DestroyImmediate(a2);
        }
    }
}
