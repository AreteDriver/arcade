using NUnit.Framework;
using UnityEngine;
using YokaiBlade.Core.Telegraphs;

namespace YokaiBlade.Tests.EditMode
{
    /// <summary>
    /// Unit tests for Telegraph System.
    ///
    /// Gate 2 Acceptance Criteria:
    /// - One semantic always produces the same meaning everywhere
    /// - Bosses cannot override semantic meaning
    /// </summary>
    public class TelegraphSystemTests
    {
        #region TelegraphSemantic Tests

        [Test]
        public void TelegraphSemantic_HasExpectedValues()
        {
            // Verify all expected semantics exist
            Assert.That(System.Enum.IsDefined(typeof(TelegraphSemantic), TelegraphSemantic.None));
            Assert.That(System.Enum.IsDefined(typeof(TelegraphSemantic), TelegraphSemantic.PerfectDeflectWindow));
            Assert.That(System.Enum.IsDefined(typeof(TelegraphSemantic), TelegraphSemantic.UndodgeableHazard));
            Assert.That(System.Enum.IsDefined(typeof(TelegraphSemantic), TelegraphSemantic.Illusion));
            Assert.That(System.Enum.IsDefined(typeof(TelegraphSemantic), TelegraphSemantic.ArenaWideThreat));
            Assert.That(System.Enum.IsDefined(typeof(TelegraphSemantic), TelegraphSemantic.StrikeWindowOpen));
        }

        [Test]
        public void TelegraphSemantic_None_IsZero()
        {
            // None should be the default/zero value
            Assert.That((int)TelegraphSemantic.None, Is.EqualTo(0));
        }

        [Test]
        public void TelegraphSemantic_AllValuesUnique()
        {
            var values = System.Enum.GetValues(typeof(TelegraphSemantic));
            var seen = new System.Collections.Generic.HashSet<int>();

            foreach (var value in values)
            {
                int intValue = (int)value;
                Assert.That(seen.Contains(intValue), Is.False,
                    $"Duplicate enum value: {intValue}");
                seen.Add(intValue);
            }
        }

        #endregion

        #region TelegraphContext Tests

        [Test]
        public void TelegraphContext_FromTransform_CapturesPosition()
        {
            var go = new GameObject("TestSource");
            go.transform.position = new Vector3(1, 2, 3);

            var context = TelegraphContext.FromTransform(go.transform);

            Assert.That(context.Position, Is.EqualTo(new Vector3(1, 2, 3)));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void TelegraphContext_FromTransform_CapturesDirection()
        {
            var go = new GameObject("TestSource");
            go.transform.forward = Vector3.right;

            var context = TelegraphContext.FromTransform(go.transform);

            Assert.That(context.Direction, Is.EqualTo(Vector3.right).Using<Vector3>((a, b) =>
                Vector3.Distance(a, b) < 0.001f ? 0 : 1));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void TelegraphContext_FromTransform_StoresAttackId()
        {
            var go = new GameObject("TestSource");

            var context = TelegraphContext.FromTransform(go.transform, attackId: "TestAttack");

            Assert.That(context.AttackId, Is.EqualTo("TestAttack"));

            Object.DestroyImmediate(go);
        }

        [Test]
        public void TelegraphContext_AtPosition_SetsPosition()
        {
            var context = TelegraphContext.AtPosition(new Vector3(5, 6, 7));

            Assert.That(context.Position, Is.EqualTo(new Vector3(5, 6, 7)));
            Assert.That(context.Source, Is.Null);
        }

        [Test]
        public void TelegraphContext_DefaultDirection_IsForward()
        {
            var context = new TelegraphContext(Vector3.zero);

            Assert.That(context.Direction, Is.EqualTo(Vector3.forward));
        }

        [Test]
        public void TelegraphContext_NullAttackId_BecomesEmptyString()
        {
            var context = new TelegraphContext(Vector3.zero, attackId: null);

            Assert.That(context.AttackId, Is.EqualTo(string.Empty));
        }

        #endregion

        #region TelegraphCatalog Tests

        [Test]
        public void TelegraphCatalog_CanBeCreated()
        {
            var catalog = ScriptableObject.CreateInstance<TelegraphCatalog>();

            Assert.That(catalog, Is.Not.Null);

            Object.DestroyImmediate(catalog);
        }

        [Test]
        public void TelegraphCatalog_EmptyCatalog_FailsValidation()
        {
            var catalog = ScriptableObject.CreateInstance<TelegraphCatalog>();

            bool valid = catalog.Validate(out var errors);

            Assert.That(valid, Is.False);
            Assert.That(errors.Count, Is.GreaterThan(0));

            Object.DestroyImmediate(catalog);
        }

        [Test]
        public void TelegraphCatalog_GetEntry_ReturnsNullForMissing()
        {
            var catalog = ScriptableObject.CreateInstance<TelegraphCatalog>();

            var entry = catalog.GetEntry(TelegraphSemantic.PerfectDeflectWindow);

            // Should return null (and log error, but we can't easily test that)
            Assert.That(entry, Is.Null);

            Object.DestroyImmediate(catalog);
        }

        [Test]
        public void TelegraphCatalog_HasEntry_ReturnsFalseForMissing()
        {
            var catalog = ScriptableObject.CreateInstance<TelegraphCatalog>();

            bool has = catalog.HasEntry(TelegraphSemantic.PerfectDeflectWindow);

            Assert.That(has, Is.False);

            Object.DestroyImmediate(catalog);
        }

        #endregion

        #region TelegraphEntry Tests

        [Test]
        public void TelegraphEntry_None_FailsValidation()
        {
            var entry = new TelegraphEntry
            {
                Semantic = TelegraphSemantic.None
            };

            bool valid = entry.Validate(out var error);

            Assert.That(valid, Is.False);
            Assert.That(error, Does.Contain("None"));
        }

        [Test]
        public void TelegraphEntry_NoAssets_FailsValidation()
        {
            var entry = new TelegraphEntry
            {
                Semantic = TelegraphSemantic.PerfectDeflectWindow,
                VfxPrefab = null,
                AudioClip = null
            };

            bool valid = entry.Validate(out var error);

            Assert.That(valid, Is.False);
            Assert.That(error, Does.Contain("no VFX or audio"));
        }

        #endregion

        #region Semantic Invariant Tests

        [Test]
        public void SemanticInvariant_NoOverridePathsExist()
        {
            // This test verifies that TelegraphCatalog has no public methods
            // that would allow changing semantic meaning at runtime.

            var type = typeof(TelegraphCatalog);
            var methods = type.GetMethods(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);

            foreach (var method in methods)
            {
                // Check for dangerous method patterns
                string name = method.Name.ToLower();
                Assert.That(name, Does.Not.Contain("override"),
                    $"Found potential override method: {method.Name}");
                Assert.That(name, Does.Not.Contain("setentry"),
                    $"Found potential entry setter: {method.Name}");
                Assert.That(name, Does.Not.Contain("addentry"),
                    $"Found potential entry adder: {method.Name}");
                Assert.That(name, Does.Not.Contain("removeentry"),
                    $"Found potential entry remover: {method.Name}");
            }
        }

        [Test]
        public void SemanticInvariant_CatalogEntriesAreImmutable()
        {
            // TelegraphEntry is a class (for serialization), but the catalog
            // should not expose mutable access to entries.

            var type = typeof(TelegraphCatalog);

            // Verify _entries is private
            var entriesField = type.GetField("_entries",
                System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
            Assert.That(entriesField, Is.Not.Null, "Expected private _entries field");
            Assert.That(entriesField.IsPrivate, Is.True, "_entries should be private");

            // Verify no public property exposes the list
            var properties = type.GetProperties(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
            foreach (var prop in properties)
            {
                Assert.That(prop.Name, Does.Not.Contain("Entries"),
                    "Should not publicly expose entries collection");
            }
        }

        #endregion
    }
}
