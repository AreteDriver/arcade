using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Boss.Oni;

namespace YokaiBlade.Tests.EditMode
{
    public class OniTests
    {
        [Test]
        public void Oni_InitialState_Inactive()
        {
            var go = new GameObject();
            var boss = go.AddComponent<OniBoss>();

            Assert.That(boss.State, Is.EqualTo(OniState.Inactive));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Oni_StartEncounter_BeginsPhase1()
        {
            var go = new GameObject();
            var boss = go.AddComponent<OniBoss>();

            boss.StartEncounter();

            Assert.That(boss.Phase, Is.EqualTo(OniPhase.Heavy));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Oni_IsVulnerable_OnlyWhenStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<OniBoss>();

            Assert.That(boss.IsVulnerable, Is.False);

            boss.ApplyStagger(1f);

            Assert.That(boss.IsVulnerable, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Oni_HasThreePhases()
        {
            Assert.That(System.Enum.GetValues(typeof(OniPhase)).Length, Is.EqualTo(3));
        }

        #region Negative Path Tests

        [Test]
        public void Oni_ApplyStagger_WhenAlreadyStaggered_ResetsTimer()
        {
            var go = new GameObject();
            var boss = go.AddComponent<OniBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(1f);

            Assert.That(boss.IsVulnerable, Is.True);

            // Stagger again - should remain vulnerable
            boss.ApplyStagger(2f);

            Assert.That(boss.IsVulnerable, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Oni_Phase_DoesNotChangeWithoutDamage()
        {
            var go = new GameObject();
            var boss = go.AddComponent<OniBoss>();

            boss.StartEncounter();
            OniPhase initialPhase = boss.Phase;

            // Stagger but don't damage
            boss.ApplyStagger(1f);

            Assert.That(boss.Phase, Is.EqualTo(initialPhase), "Phase should not change without damage");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Oni_StartEncounter_WhenAlreadyActive_ResetsState()
        {
            var go = new GameObject();
            var boss = go.AddComponent<OniBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(1f);

            // Restart encounter
            boss.StartEncounter();

            Assert.That(boss.Phase, Is.EqualTo(OniPhase.Heavy), "Should reset to first phase");
            Assert.That(boss.IsVulnerable, Is.False, "Should not be vulnerable after restart");

            Object.DestroyImmediate(go);
        }

        #endregion
    }
}
