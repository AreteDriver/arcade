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

        #region Negative Path Tests

        [Test]
        public void Tanuki_TakeDamage_WhenNotVulnerable_StillReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            Assert.That(boss.IsVulnerable, Is.False);
            boss.TakeDamage();

            // Current implementation reduces health regardless of vulnerability
            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Tanuki_ApplyStagger_MultipleTimes_OverwritesDuration()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(1f);
            boss.ApplyStagger(2f); // Apply again with different duration

            // Should still be vulnerable (staggered state maintained)
            Assert.That(boss.IsVulnerable, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void Tanuki_StartEncounter_ResetsHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<TanukiBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            boss.ApplyStagger(1f);
            boss.TakeDamage();

            // Start encounter again should reset health
            boss.StartEncounter();

            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth));

            Object.DestroyImmediate(go);
        }

        #endregion
    }
}
