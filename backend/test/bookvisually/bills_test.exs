defmodule BookVisually.BillsTest do
  use BookVisually.DataCase

  alias BookVisually.Bills
  alias BookVisually.Resources

  describe "utility_bills" do
    setup do
      {:ok, resource} = Resources.create_utility_resource(%{
        name: "Water Bill",
        resource_category: "utility",
        utility_properties: %{
          bill_type: "utility",
          billing_cycle_days: 30
        }
      })

      %{resource: resource}
    end

    @valid_attrs %{
      bill_date: ~D[2026-03-01],
      due_date: ~D[2026-03-15],
      bill_reading: Decimal.new("1750.5"),
      previous_reading: Decimal.new("1500.0"),
      unit_of_measure: "liters",
      unit_cost: Decimal.new("0.30"),
      total_amount: Decimal.new("75.15"),
      vendor: "Water Utility Co"
    }

    @invalid_attrs %{
      bill_date: nil,
      total_amount: nil
    }

    test "list_bills/0 returns all active bills", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      bills = Bills.list_bills()
      assert length(bills) == 1
      assert hd(bills).id == bill.id
    end

    test "list_bills/0 does not return deleted bills", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)
      {:ok, _deleted} = Bills.soft_delete_bill(bill)

      bills = Bills.list_bills()
      assert bills == []
    end

    test "list_bills_by_resource/1 filters by resource", %{resource: resource} do
      {:ok, other_resource} = Resources.create_utility_resource(%{
        name: "Electricity",
        resource_category: "utility",
        utility_properties: %{bill_type: "utility"}
      })

      attrs1 = Map.put(@valid_attrs, :resource_id, resource.id)
      attrs2 = Map.put(@valid_attrs, :resource_id, other_resource.id)

      {:ok, bill1} = Bills.create_bill(attrs1)
      {:ok, _bill2} = Bills.create_bill(attrs2)

      bills = Bills.list_bills_by_resource(resource.id)
      assert length(bills) == 1
      assert hd(bills).id == bill1.id
    end

    test "list_bills_by_status/1 filters by status", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)
      {:ok, _paid} = Bills.mark_as_paid(bill)

      unpaid_bills = Bills.list_bills_by_status("unpaid")
      paid_bills = Bills.list_bills_by_status("paid")

      assert length(unpaid_bills) == 0
      assert length(paid_bills) == 1
    end

    test "list_unpaid_bills/0 returns unpaid and partially_paid bills", %{resource: resource} do
      attrs1 = Map.put(@valid_attrs, :resource_id, resource.id)
      attrs2 = Map.put(@valid_attrs, :resource_id, resource.id)
      attrs3 = Map.put(@valid_attrs, :resource_id, resource.id)

      {:ok, _unpaid} = Bills.create_bill(attrs1)
      {:ok, partial} = Bills.create_bill(attrs2)
      {:ok, paid} = Bills.create_bill(attrs3)

      {:ok, _} = Bills.mark_as_partially_paid(partial)
      {:ok, _} = Bills.mark_as_paid(paid)

      unpaid_bills = Bills.list_unpaid_bills()
      assert length(unpaid_bills) == 2
    end

    test "list_overdue_bills/0 returns only overdue bills", %{resource: resource} do
      attrs1 = Map.put(@valid_attrs, :resource_id, resource.id)
      attrs2 = Map.put(@valid_attrs, :resource_id, resource.id)

      {:ok, _unpaid} = Bills.create_bill(attrs1)
      {:ok, overdue} = Bills.create_bill(attrs2)
      {:ok, _} = Bills.mark_as_overdue(overdue)

      overdue_bills = Bills.list_overdue_bills()
      assert length(overdue_bills) == 1
    end

    test "create_bill/1 with valid data creates a bill", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)

      assert {:ok, bill} = Bills.create_bill(attrs)
      assert bill.resource_id == resource.id
      assert bill.bill_date == ~D[2026-03-01]
      assert bill.due_date == ~D[2026-03-15]
      assert Decimal.equal?(bill.bill_reading, Decimal.new("1750.5"))
      assert Decimal.equal?(bill.previous_reading, Decimal.new("1500.0"))
      assert Decimal.equal?(bill.quantity_consumed, Decimal.new("250.5"))
      assert bill.unit_of_measure == "liters"
      assert Decimal.equal?(bill.unit_cost, Decimal.new("0.30"))
      assert Decimal.equal?(bill.total_amount, Decimal.new("75.15"))
      assert bill.vendor == "Water Utility Co"
      assert bill.status == "unpaid"
    end

    test "create_bill/1 calculates consumption from readings", %{resource: resource} do
      attrs = %{
        resource_id: resource.id,
        bill_date: ~D[2026-03-01],
        bill_reading: Decimal.new("2000"),
        previous_reading: Decimal.new("1500"),
        total_amount: Decimal.new("100")
      }

      assert {:ok, bill} = Bills.create_bill(attrs)
      assert Decimal.equal?(bill.quantity_consumed, Decimal.new("500"))
    end

    test "create_bill/1 with invalid data returns error" do
      assert {:error, %Ecto.Changeset{}} = Bills.create_bill(@invalid_attrs)
    end

    test "create_bill/1 with due_date before bill_date returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:due_date, ~D[2026-02-01])

      assert {:error, changeset} = Bills.create_bill(attrs)
      assert "must be on or after bill date" in errors_on(changeset).due_date
    end

    test "create_bill/1 with negative total_amount returns error", %{resource: resource} do
      attrs = @valid_attrs
      |> Map.put(:resource_id, resource.id)
      |> Map.put(:total_amount, Decimal.new("-50"))

      assert {:error, changeset} = Bills.create_bill(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).total_amount
    end

    test "update_bill/2 with valid data updates the bill", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      update_attrs = %{vendor: "New Water Co", reference_number: "WB-2026-001"}
      assert {:ok, updated} = Bills.update_bill(bill, update_attrs)
      assert updated.vendor == "New Water Co"
      assert updated.reference_number == "WB-2026-001"
    end

    test "soft_delete_bill/1 marks bill as deleted", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      assert {:ok, deleted} = Bills.soft_delete_bill(bill)
      assert deleted.is_deleted == true
      assert deleted.deleted_at != nil
      assert Bills.list_bills() == []
    end

    test "restore_bill/1 restores a deleted bill", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)
      {:ok, deleted} = Bills.soft_delete_bill(bill)

      assert {:ok, restored} = Bills.restore_bill(deleted)
      assert restored.is_deleted == false
      assert restored.deleted_at == nil
      assert length(Bills.list_bills()) == 1
    end

    test "mark_as_paid/1 updates bill status to paid", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      assert {:ok, updated} = Bills.mark_as_paid(bill)
      assert updated.status == "paid"
    end

    test "mark_as_partially_paid/1 updates bill status", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      assert {:ok, updated} = Bills.mark_as_partially_paid(bill)
      assert updated.status == "partially_paid"
    end

    test "mark_as_overdue/1 updates bill status", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      assert {:ok, updated} = Bills.mark_as_overdue(bill)
      assert updated.status == "overdue"
    end

    test "cancel_bill/1 updates bill status to cancelled", %{resource: resource} do
      attrs = Map.put(@valid_attrs, :resource_id, resource.id)
      {:ok, bill} = Bills.create_bill(attrs)

      assert {:ok, updated} = Bills.cancel_bill(bill)
      assert updated.status == "cancelled"
    end

    test "get_total_unpaid/0 returns sum of unpaid bills", %{resource: resource} do
      attrs1 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:total_amount, Decimal.new("100"))
      attrs2 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:total_amount, Decimal.new("150"))
      attrs3 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:total_amount, Decimal.new("200"))

      {:ok, _unpaid1} = Bills.create_bill(attrs1)
      {:ok, _unpaid2} = Bills.create_bill(attrs2)
      {:ok, paid} = Bills.create_bill(attrs3)
      {:ok, _} = Bills.mark_as_paid(paid)

      total = Bills.get_total_unpaid()
      assert Decimal.equal?(total, Decimal.new("250"))
    end

    test "get_total_unpaid_for_resource/1 returns sum for specific resource", %{resource: resource} do
      {:ok, other_resource} = Resources.create_utility_resource(%{
        name: "Electricity",
        resource_category: "utility",
        utility_properties: %{bill_type: "utility"}
      })

      attrs1 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:total_amount, Decimal.new("100"))
      attrs2 = @valid_attrs |> Map.put(:resource_id, other_resource.id) |> Map.put(:total_amount, Decimal.new("200"))

      {:ok, _} = Bills.create_bill(attrs1)
      {:ok, _} = Bills.create_bill(attrs2)

      total = Bills.get_total_unpaid_for_resource(resource.id)
      assert Decimal.equal?(total, Decimal.new("100"))
    end

    test "mark_overdue_bills/0 marks past due bills as overdue", %{resource: resource} do
      past_due = Date.add(Date.utc_today(), -5)
      future_due = Date.add(Date.utc_today(), 5)

      attrs1 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:due_date, past_due)
      attrs2 = @valid_attrs |> Map.put(:resource_id, resource.id) |> Map.put(:due_date, future_due)

      {:ok, overdue_bill} = Bills.create_bill(attrs1)
      {:ok, future_bill} = Bills.create_bill(attrs2)

      Bills.mark_overdue_bills()

      updated_overdue = Bills.get_bill!(overdue_bill.id)
      updated_future = Bills.get_bill!(future_bill.id)

      assert updated_overdue.status == "overdue"
      assert updated_future.status == "unpaid"
    end
  end
end
