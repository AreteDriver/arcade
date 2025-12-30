using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Boss.ChochinObake;
using YokaiBlade.Core.Combat;

namespace YokaiBlade.Tests.EditMode
{
    public class ChochinObakeTests
    {
        [Test]
        public void ChochinObake_InitialState_Inactive()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Inactive));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_StartEncounter_TransitionsToIntro()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();

            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Intro));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_StartEncounter_ResetsHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();

            Assert.That(boss.CurrentHealth, Is.EqualTo(2));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_StartEncounter_ResetsAttackCount()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();

            Assert.That(boss.AttackCount, Is.EqualTo(0));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_IsVulnerable_OnlyWhenStaggered()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            Assert.That(boss.IsVulnerable, Is.False);

            boss.ApplyStagger(1f);

            Assert.That(boss.IsVulnerable, Is.True);
            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Staggered));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_TakeDamage_ReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_TakeDamage_DefeatsWhenHealthZero()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.StartEncounter();

            // Take damage until defeated
            boss.ApplyStagger(1f);
            boss.TakeDamage();
            boss.ApplyStagger(1f);
            boss.TakeDamage();

            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_Defeat_TransitionsToDefeated()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();
            bool defeated = false;
            boss.OnDefeated += () => defeated = true;

            boss.StartEncounter();
            boss.Defeat();

            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Defeated));
            Assert.That(defeated, Is.True);

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_GetCurrentExpectedResponse_ReturnsCorrectResponse()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            // Before any attack, should be None
            Assert.That(boss.GetCurrentExpectedResponse(), Is.EqualTo(AttackResponse.None));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_HasCorrectStateCount()
        {
            // 8 states: Inactive, Intro, Float, TongueLash, FlameBreath, Flicker, Staggered, Defeated
            Assert.That(System.Enum.GetValues(typeof(ChochinObakeState)).Length, Is.EqualTo(8));
        }

        #region Negative Path Tests

        [Test]
        public void ChochinObake_TakeDamage_WhenNotVulnerable_StillReducesHealth()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();
            int initialHealth = boss.CurrentHealth;

            Assert.That(boss.IsVulnerable, Is.False);
            boss.TakeDamage();

            // Current implementation reduces health regardless
            Assert.That(boss.CurrentHealth, Is.EqualTo(initialHealth - 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_Defeat_WhenAlreadyDefeated_DoesNotFireEventAgain()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();
            int defeatedCount = 0;
            boss.OnDefeated += () => defeatedCount++;

            boss.StartEncounter();
            boss.Defeat();
            boss.Defeat(); // Call again

            Assert.That(defeatedCount, Is.EqualTo(1), "OnDefeated should only fire once");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_ApplyStagger_WhenDefeated_DoesNotChangeState()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();
            boss.Defeat();

            // Try to stagger after defeated
            boss.ApplyStagger(1f);

            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Defeated), "Should remain defeated");

            Object.DestroyImmediate(go);
        }

        [Test]
        public void ChochinObake_StartEncounter_ResetsAllState()
        {
            var go = new GameObject();
            var boss = go.AddComponent<ChochinObakeBoss>();

            boss.StartEncounter();
            boss.ApplyStagger(1f);
            boss.TakeDamage();

            int healthAfterDamage = boss.CurrentHealth;

            // Restart encounter
            boss.StartEncounter();

            Assert.That(boss.CurrentHealth, Is.EqualTo(2), "Health should reset");
            Assert.That(boss.AttackCount, Is.EqualTo(0), "Attack count should reset");
            Assert.That(boss.State, Is.EqualTo(ChochinObakeState.Intro), "State should be Intro");

            Object.DestroyImmediate(go);
        }

        #endregion
    }
}
