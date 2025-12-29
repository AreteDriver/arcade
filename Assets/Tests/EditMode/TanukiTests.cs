using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Boss.Tanuki;

namespace YokaiBlade.Tests.EditMode
{
    public class TanukiTests
    {
        [Test]
        public void Tanuki_InitialState_Inactive()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();

            Assert.That(boss.State, Is.EqualTo(TanukiState.Inactive));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Tanuki_StartEncounter_TransitionsToIntro()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();

            boss.StartEncounter();

            Assert.That(boss.State, Is.EqualTo(TanukiState.Intro));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Tanuki_IsVulnerable_OnlyWhenStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();

            Assert.That(boss.IsVulnerable, Is.False);

            boss.ApplyStagger(1f);

            Assert.That(boss.IsVulnerable, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Tanuki_TakeDamage_DecreasesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();
            boss.StartEncounter();
            int initial = boss.CurrentHealth;

            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.CurrentHealth, Is.EqualTo(initial - 1));

            Object.DestroyImmediate(go);
        }
    }
}
