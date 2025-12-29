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
    }
}
